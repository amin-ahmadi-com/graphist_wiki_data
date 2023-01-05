import 'dart:convert';

import 'package:graphist/graphist.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import 'wiki_data_utils.dart';

enum WikiDataNodeType {
  entity,
}

class WikiDataEntityNode extends Node {
  final String entityId;
  final String title;
  final String wikiUrl;
  final String? description;

  WikiDataEntityNode({
    required this.entityId,
    required this.title,
    required this.wikiUrl,
    this.description,
  }) : super(
          type: WikiDataNodeType.entity.toString(),
          properties: {
            "entityId": entityId,
            "title": title,
            "wikiUrl": wikiUrl,
            "description": description,
          },
          labelProperty: "title",
          uniqueProperty: "entityId",
          urlProperty: "wikiUrl",
          icon: const NodeIcon(
            fontFamily: "MaterialIcons",
            codePoint: 0xe559, // School icon
          ),
        );

  @override
  Future<Iterable<Tuple2<Relation, Node>>> get relatives async {
    var result = <Tuple2<Relation, Node>>[];
    final client = http.Client();

    var response = await client.get(
      Uri.parse(
          "https://www.wikidata.org/wiki/Special:EntityData/$entityId.json"),
    );

    if (response.statusCode != 200) return result;

    final data = jsonDecode(response.body);

    List<String> claimKeys = (data["entities"][entityId]["claims"] as Map)
        .keys
        .map<String>((e) => e)
        .toList();

    var claims = <String, List<String>>{};
    for (var claim in claimKeys) {
      final claimItems = (data["entities"][entityId]["claims"][claim] as List)
          .map((claimItem) {
            try {
              return claimItem["mainsnak"]["datavalue"]["value"]["id"];
            } catch (_) {}
          })
          .where((element) => element != null)
          .toList();
      claims[claim] = claimItems.cast<String>();
    }

    final futureResults = <Future>[];
    for (final claim in claims.entries) {
      for (final node in claim.value) {
        final f = Future.microtask(() async {
          final toNode = await WikiDataEntityNode.tryFromWikidata(node);
          if (toNode == null) {
            return;
          }
          final relation = await WikiDataUtils.tryFromWikidata(
            this,
            toNode,
            claim.key,
          );
          if (relation == null) {
            return;
          }
          result.add(Tuple2(relation, toNode));
        });
        futureResults.add(f);
      }
    }

    await Future.wait(futureResults);

    return result;
  }

  static Future<WikiDataEntityNode?> tryFromWikidata(String entityId,
      {http.Client? client}) {
    try {
      return WikiDataEntityNode._fromWikidata(entityId, client: client);
    } catch (e) {
      return Future(() => null);
    }
  }

  static Future<WikiDataEntityNode?> _fromWikidata(String entityId,
      {http.Client? client}) async {
    client ??= http.Client();
    var response = await client.get(
      Uri.parse(
          "https://www.wikidata.org/wiki/Special:EntityData/$entityId.json"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final entity = data["entities"][entityId];
      final sitelinks = entity["sitelinks"];
      if (sitelinks == null) return null;
      final enwiki = sitelinks["enwiki"];
      if (enwiki == null) return null;
      final title = enwiki["title"];
      final url = enwiki["url"];
      final en = entity["descriptions"]["en"];
      if (en == null) return null;
      final description = en["value"];
      final entityClaims = entity["claims"] as Map;

      List<String> claimKeys = entityClaims.keys.map<String>((e) => e).toList();
      var claims = <String, List<String>>{};

      for (var claim in claimKeys) {
        final claimItems = (entityClaims[claim] as List)
            .map((claimItem) {
              try {
                return claimItem["mainsnak"]["datavalue"]["value"]["id"];
              } catch (_) {}
            })
            .where((element) => element != null)
            .toList();
        claims[claim] = claimItems.cast<String>();
      }

      return WikiDataEntityNode(
        entityId: entityId,
        title: title,
        wikiUrl: url,
        description: description,
      );
    } else {
      return null;
    }
  }
}

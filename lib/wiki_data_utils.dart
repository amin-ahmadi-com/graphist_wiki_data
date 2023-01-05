import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'wiki_data_nodes.dart';
import 'wiki_data_relations.dart';

class WikiDataSearchResult {
  final String entityId;
  final String snippet;

  WikiDataSearchResult(this.entityId, this.snippet);

  static WikiDataSearchResult fromJson({String? sj, dynamic dj}) {
    if (sj != null && dj != null) throw UnimplementedError();
    dj ??= jsonEncode(sj);
    return WikiDataSearchResult(
      dj["title"],
      dj["snippet"],
    );
  }
}

class WikiDataUtils {
  static Future<List<WikiDataSearchResult>> searchWikiData(
    String query, {
    http.Client? client,
  }) async {
    final result = <WikiDataSearchResult>[];
    client ??= http.Client();
    var response = await client.get(
      Uri.parse(
        'https://www.wikidata.org/w/api.php?'
        'action=query'
        '&'
        'list=search'
        '&'
        'format=json'
        '&'
        'srsearch=$query',
      ),
    );
    if (response.statusCode == 200) {
      for (final q in jsonDecode(response.body)["query"]["search"]) {
        result.add(WikiDataSearchResult.fromJson(dj: q));
      }
    } else {
      if (kDebugMode) {
        print(response.statusCode);
        print(response.reasonPhrase);
        print(response.body);
      }
    }
    return result;
  }

  static Future<WikiDataLinksRelation?> tryFromWikidata(
    WikiDataEntityNode from,
    WikiDataEntityNode to,
    String wikiRelationId, {
    http.Client? client,
  }) {
    try {
      return _fromWikidata(
        from,
        to,
        wikiRelationId,
        client: client,
      );
    } catch (e) {
      return Future(() => null);
    }
  }

  static Future<WikiDataLinksRelation?> _fromWikidata(
    WikiDataEntityNode from,
    WikiDataEntityNode to,
    String wikiRelationId, {
    http.Client? client,
  }) async {
    client ??= http.Client();
    var response = await client.get(
      Uri.parse(
        "https://www.wikidata.org/wiki/Special:EntityData/$wikiRelationId.json",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final label = data["entities"][wikiRelationId]["labels"]["en"]["value"];
      final description =
          data["entities"][wikiRelationId]["descriptions"]["en"]["value"];

      return WikiDataLinksRelation(
        from.id,
        to.id,
        wikiRelationId,
        wikiLabel: label,
        description: description,
      );
    } else {
      if (kDebugMode) {
        print(response.statusCode);
        print(response.reasonPhrase);
        print(response.body);
      }
      return null;
    }
  }
}

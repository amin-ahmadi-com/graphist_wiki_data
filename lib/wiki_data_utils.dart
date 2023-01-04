import 'dart:convert';

import 'package:http/http.dart' as http;

import 'wiki_data_nodes.dart';
import 'wiki_data_relations.dart';

class WikiDataUtils {
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
          "https://www.wikidata.org/wiki/Special:EntityData/$wikiRelationId.json"),
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
      return null;
    }
  }
}

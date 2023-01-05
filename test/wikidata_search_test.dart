import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphist_wiki_data/wiki_data_utils.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'wikidata_search_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  test("Search Sydney in Wikidata", () async {
    final mockClient = MockClient();
    when(
      mockClient.get(
        Uri.parse(
          "https://www.wikidata.org/w/api.php?action=query&list=search&format=json&srsearch=sydney",
        ),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        File(
          "./test/wikidata_search.json",
        ).readAsStringSync(),
        200,
      ),
    );

    final result = await WikiDataUtils.searchWikiData("Sydney");

    expect(result.length, 10);
  });
}

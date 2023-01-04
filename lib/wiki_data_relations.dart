import 'package:graphist/graphist.dart';

enum WikiDataRelationType {
  links,
}

class WikiDataLinksRelation extends Relation {
  String? wikiRelationId; // Entity ID
  String? wikiLabel;
  String? description;

  WikiDataLinksRelation(
    String fromNodeId,
    String toNodeId,
    this.wikiRelationId, {
    this.wikiLabel,
    this.description,
  }) : super(
          type: WikiDataRelationType.links.toString(),
          properties: {
            "wikiRelationId": wikiRelationId,
            "wikiLabel": wikiLabel,
            "description": description,
          },
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          labelProperty: "wikiLabel",
        );

  @override
  Map<String, dynamic> get properties => {
        "wikiRelationId": wikiRelationId,
        "wikiLabel": wikiLabel,
        "description": description,
      };
}

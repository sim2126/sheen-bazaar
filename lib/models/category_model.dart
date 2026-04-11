class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String icon;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.icon,
    required this.description,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? '';
    return CategoryModel(
      id: id,
      name: name,
      image: data['image'] ?? '',
      icon: data['icon'] ?? '',
      description: data['description'] ?? _fallbackDescription(name),
    );
  }
}

String _fallbackDescription(String name) {
  const map = {
    'Pashmina': 'Hand-woven from the finest Himalayan wool, treasured across centuries.',
    'Crewelwork': 'Intricate floral needlework embroidered on fabric by Kashmiri artisans.',
    'Papier-Mâché': 'Delicate hand-painted objects crafted from layered paper pulp.',
    'Namda': 'Traditional felted wool rugs with vibrant hand-stitched patterns.',
    'Walnut Wood': 'Finely carved furniture and decor from Kashmiri walnut timber.',
    'Copper Work': 'Hand-beaten copper vessels shaped by generations of craftsmen.',
    'Kani': 'Centuries-old tapestry weaving technique producing exquisite shawls.',
    'Sozni': 'Fine needle embroidery creating delicate patterns on pashmina and silk.',
    'Carpet': 'Hand-knotted rugs woven with geometric and floral motifs over months.',
    'Silverwork': 'Intricate filigree jewellery and artefacts shaped by master silversmiths.',
  };
  return map[name] ?? 'Authentic craftsmanship from the artisans of Kashmir.';
}

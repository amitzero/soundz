class ArtistItem {
  String id;
  String name;
  String url;
  String? image;
  ArtistItem({
    required this.id,
    required this.name,
    required this.url,
    this.image,
  });
  ArtistItem.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        url = map['url'],
        image = map['image'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'image': image,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ArtistItem && other.hashCode == hashCode;
  }
}

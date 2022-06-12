class ArtistItem {
  String id;
  String name;
  ArtistItem({
    required this.id,
    required this.name,
  });
  ArtistItem.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() => '$name($id)';
}

class ArtistItemInfo extends ArtistItem {
  String url;
  String? image;
  ArtistItemInfo({
    required super.id,
    required super.name,
    required this.url,
    this.image,
  });

  ArtistItemInfo.fromJson(Map<String, dynamic> map)
      : url = map['url'],
        image = map['image'],
        super.fromJson(map);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'image': image,
      };

  ArtistItem get info => ArtistItem(
        id: id,
        name: name,
      );

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistItemInfo && hashCode == other.hashCode);

  @override
  String toString() => '$name($id, $url, $image)';
}

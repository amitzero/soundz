class ArtistItemInfo {
  String id;
  String name;
  ArtistItemInfo({
    required this.id,
    required this.name,
  });
  ArtistItemInfo.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() => '$name($id)';
}

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

  ArtistItemInfo get info => ArtistItemInfo(
        id: id,
        name: name,
      );

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistItem && hashCode == other.hashCode);

  @override
  String toString() => '$name($id, $url, $image)';
}

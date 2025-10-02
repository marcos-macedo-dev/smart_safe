
class ContactLocal {
  int? id;
  String name;
  String phone;
  String? email;
  String? parentesco;
  bool isSynced; // To track if the contact has been synced with the server

  ContactLocal({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.parentesco,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'parentesco': parentesco,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ContactLocal.fromMap(Map<String, dynamic> map) {
    return ContactLocal(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      parentesco: map['parentesco'],
      isSynced: map['isSynced'] == 1,
    );
  }
}

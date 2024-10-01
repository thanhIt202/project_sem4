import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../model/Users.dart';
import '../../../service/User_Service.dart';
import '../../../service/data.dart';

class EditAccountFormScreen extends StatefulWidget {
  final int userId;
  EditAccountFormScreen(this.userId);

  @override
  _EditAccountFormScreenState createState() => _EditAccountFormScreenState();
}

class _EditAccountFormScreenState extends State<EditAccountFormScreen> {
  late UserService service;
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // For avatar selection
  File? _avatar;
  final picker = ImagePicker();
  String? _currentImagePath;

  // For status selection
  String? _selectedStatus;
  final List<String> _status = ["validity", "locked"];

  Future<void> connectDatabase() async {
    service = UserService(await getDatabase());
    Users? user = await service.getById(widget.userId);
    if (user != null) {
      setState(() {
        _fullNameController.text = user.full_name;
        _userNameController.text = user.user_name;
        _emailController.text = user.email;
        _passwordController.text = user.password_hash;
        _selectedStatus = user.status;
        _currentImagePath = user.avatar;
      });
    } else {
      // Handle user not found (e.g., show an error message)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User not found')));
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    connectDatabase();
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
        _currentImagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit User'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter Full name, cannot be left blank'
                      : null,
                  readOnly: true, // Cho phép xem nhưng không cho chỉnh sửa
                ),
                TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(labelText: 'User Name'),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter User name, cannot be left blank'
                      : null,
                  readOnly: true, // Cho phép xem nhưng không cho chỉnh sửa
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'User email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter User email, cannot be left blank';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  readOnly: true, // Cho phép xem nhưng không cho chỉnh sửa
                ),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: _status
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedStatus = newValue),
                  validator: (value) => value == null
                      ? 'Please select status, cannot be left blank'
                      : null,
                ),
                const SizedBox(height: 60),
                _avatar != null
                    ? Image.file(_avatar!, height: 100)
                    : _currentImagePath != null
                        ? _buildUserImage(_currentImagePath!)
                        : Text('No image selected'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String imagePath =
                            _avatar?.path ?? _currentImagePath ?? '';
                        Users updatedUser = Users(
                          user_id: widget.userId,
                          full_name: _fullNameController.text,
                          user_name: _userNameController.text,
                          email: _emailController.text,
                          password_hash: _passwordController.text,
                          avatar: imagePath,
                          role: 'user', // Set role appropriately
                          status: _selectedStatus!,
                        );

                        try {
                          await service.update(updatedUser);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('User updated successfully!')));
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed to update user: $e')));
                        }
                      }
                    },
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserImage(String imagePath) {
    return imagePath.startsWith('/data/')
        ? Image.file(File(imagePath),
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.error))
        : Image.asset("assets/images/users/$imagePath",
            height: 100, fit: BoxFit.cover);
  }
}

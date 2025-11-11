import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';

class AbcGroupAddScreen1 extends StatefulWidget {
  final String? abcId;

  const AbcGroupAddScreen1({super.key, this.abcId});

  @override
  State<AbcGroupAddScreen1> createState() => _AbcGroupAddScreen1State();
}

class _AbcGroupAddScreen1State extends State<AbcGroupAddScreen1> {
  int? _selectedCharacterIndex;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> availableCharacters = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCharacters();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCharacters() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final usedCharacterDocs =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('abc_group')
            .get();

    final usedCharacterIds =
        usedCharacterDocs.docs
            .map((doc) => int.tryParse('${doc['group_id']}') ?? -1)
            .toSet();

    final allCharacters = List.generate(
      20,
      (index) => {
        'id': index + 1,
        'name': '캐릭터 ${index + 1}',
        'image': 'assets/image/character${index + 1}.png',
      },
    );

    setState(() {
      availableCharacters =
          allCharacters
              .where((char) => !usedCharacterIds.contains(char['id']))
              .toList();
    });
  }

  Future<void> _addGroupToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;

    if (_selectedCharacterIndex == null ||
        titleController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필드를 입력하세요.')));
      return;
    }

    final selectedCharacter = availableCharacters[_selectedCharacterIndex!];

    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("abc_group")
          .add({
            'userId': userId,
            'group_id': selectedCharacter['id'].toString(),
            'group_title': titleController.text,
            'group_contents': descriptionController.text,
            'archived': null, // 초기값
            'archived_at': null, // 초기값
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그룹이 성공적으로 추가되었습니다!')));

      // ✅ 다음 화면으로 push하지 않고, 호출한 화면으로 돌아갑니다.
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(title: '그룹 생성'),
      body:
          availableCharacters.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '캐릭터 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: screenHeight * 0.3,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableCharacters.length,
                        itemBuilder: (context, index) {
                          final character = availableCharacters[index];
                          final isSelected = _selectedCharacterIndex == index;
                          return GestureDetector(
                            onTap:
                                () => setState(
                                  () => _selectedCharacterIndex = index,
                                ),
                            child: Container(
                              width: screenWidth * 0.3,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.indigo
                                          : Colors.grey.shade300,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    character['image'],
                                    height: screenHeight * 0.2,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    character['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.indigo
                                              : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '그룹 제목',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '그룹 제목을 입력하세요',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '그룹 설명',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '그룹 설명을 입력하세요',
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: '이전',
          rightLabel: '추가',
          onBack: () => Navigator.pop(context),
          onNext: _addGroupToFirebase,
        ),
      ),
    );
  }
}

// ============================================================
// 🛡️ لوحة التحكم - النسخة الكاملة
// استبدل _AdminPublishTab و _AdminEditTab في main.dart بهذا الملف
//
// الاستخدام:
//   1. أضف هذا الملف إلى مشروعك
//   2. استبدل class _AdminPublishTab و _AdminEditTab في main.dart
//      بالنسخ الموجودة هنا
//   3. تأكد من وجود: http, image_picker في pubspec.yaml
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ────────────────────────────────────────────────────────────
// ثوابت
// ────────────────────────────────────────────────────────────
const String _baseUrl = 'https://scrptaty.com/posts';
const String _apiAdd = '$_baseUrl/api_add_post.php';
const String _apiList = '$_baseUrl/api_get_posts.php';
const String _apiEdit = '$_baseUrl/api_edit_post.php';
const String _apiDelete = '$_baseUrl/api_delete_post.php';

// ────────────────────────────────────────────────────────────
// نموذج البيانات
// ────────────────────────────────────────────────────────────
class AdminPost {
  final String id;
  final String title;
  final String description;
  final String image;
  final String file;
  final String type; // normal | file | simple

  AdminPost({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.file,
    required this.type,
  });

  factory AdminPost.fromJson(Map<String, dynamic> j) => AdminPost(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        image: j['image']?.toString() ?? '',
        file: j['file']?.toString() ?? '',
        type: j['type']?.toString() ?? 'normal',
      );

  String get imageUrl {
    final img = image;
    if (img.isEmpty) return '';
    return img.startsWith('http') ? img : '$_baseUrl/$img';
  }
}

// ────────────────────────────────────────────────────────────
// تاب النشر
// ────────────────────────────────────────────────────────────
class _AdminPublishTab extends StatefulWidget {
  final bool isDark;
  const _AdminPublishTab({required this.isDark});

  @override
  State<_AdminPublishTab> createState() => _AdminPublishTabState();
}

class _AdminPublishTabState extends State<_AdminPublishTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'normal'; // normal | file | simple
  XFile? _imageFile;
  XFile? _attachFile;
  bool _loading = false;
  String? _msg;
  bool _success = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final f = await p.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) setState(() => _imageFile = f);
  }

  Future<void> _pickFile() async {
    // استخدام image_picker للملفات العامة غير متوفر مباشرة
    // يمكنك استبداله بـ file_picker إذا أضفته للـ pubspec
    setState(() => _msg = 'قريباً: رفع الملفات');
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _show('يرجى إدخال العنوان', false);
      return;
    }
    if (_imageFile == null) {
      _show('يرجى اختيار صورة', false);
      return;
    }
    if (_type == 'normal' && _descCtrl.text.trim().isEmpty) {
      _show('يرجى إدخال الوصف', false);
      return;
    }

    setState(() => _loading = true);

    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiAdd));
      req.fields['title'] = _titleCtrl.text.trim();
      req.fields['description'] =
          _type == 'normal' ? _descCtrl.text.trim() : '';
      req.fields['type'] = _type;

      req.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      if (_type == 'file' && _attachFile != null) {
        req.files.add(
            await http.MultipartFile.fromPath('file', _attachFile!.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);

      if (json['success'] == true) {
        _titleCtrl.clear();
        _descCtrl.clear();
        setState(() {
          _imageFile = null;
          _attachFile = null;
          _type = 'normal';
        });
        _show('✅ تم النشر بنجاح', true);
      } else {
        _show('❌ ${json['message'] ?? 'حدث خطأ'}', false);
      }
    } catch (e) {
      _show('❌ تعذر الاتصال بالخادم', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg, bool ok) {
    setState(() {
      _msg = msg;
      _success = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF111111) : const Color(0xFFF4F4F4);
    final card = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = widget.isDark ? Colors.white : Colors.black;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── رسالة الحالة ──
          if (_msg != null) ...[
            _StatusBanner(message: _msg!, success: _success, isDark: widget.isDark),
            const SizedBox(height: 14),
          ],

          // ── نوع المنشور ──
          _SectionCard(
            isDark: widget.isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('نوع المنشور', Icons.category_rounded, widget.isDark),
                const SizedBox(height: 10),
                _TypeSelector(
                  selected: _type,
                  isDark: widget.isDark,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── العنوان ──
          _SectionCard(
            isDark: widget.isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('العنوان', Icons.title_rounded, widget.isDark),
                const SizedBox(height: 10),
                _AppTextField(
                  controller: _titleCtrl,
                  hint: 'أدخل عنوان المنشور...',
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── الوصف (فقط للنوع normal) ──
          if (_type == 'normal') ...[
            _SectionCard(
              isDark: widget.isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('الوصف', Icons.notes_rounded, widget.isDark),
                  const SizedBox(height: 10),
                  _AppTextField(
                    controller: _descCtrl,
                    hint: 'اكتب وصف المنشور هنا...',
                    isDark: widget.isDark,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── الصورة ──
          _SectionCard(
            isDark: widget.isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('الصورة', Icons.image_rounded, widget.isDark),
                const SizedBox(height: 10),
                _ImagePickerBox(
                  file: _imageFile,
                  isDark: widget.isDark,
                  onTap: _pickImage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── ملف مرفق (فقط للنوع file) ──
          if (_type == 'file') ...[
            _SectionCard(
              isDark: widget.isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('ملف مرفق', Icons.attach_file_rounded, widget.isDark),
                  const SizedBox(height: 10),
                  _FilePickerBox(
                    file: _attachFile,
                    isDark: widget.isDark,
                    onTap: _pickFile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── زر النشر ──
          _SubmitButton(
            label: 'نشر المنشور',
            icon: Icons.send_rounded,
            loading: _loading,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// تاب التعديل
// ────────────────────────────────────────────────────────────
class _AdminEditTab extends StatefulWidget {
  final bool isDark;
  const _AdminEditTab({required this.isDark});

  @override
  State<_AdminEditTab> createState() => _AdminEditTabState();
}

class _AdminEditTabState extends State<_AdminEditTab> {
  List<AdminPost> _posts = [];
  bool _loading = true;
  String? _msg;
  bool _success = false;

  // حالة التعديل
  AdminPost? _editing;
  final _editTitleCtrl = TextEditingController();
  final _editDescCtrl = TextEditingController();
  String _editType = 'normal';
  XFile? _editImageFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _editTitleCtrl.dispose();
    _editDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(_apiList));
      final list = jsonDecode(res.body) as List;
      setState(() {
        _posts = list.map((e) => AdminPost.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      _show('تعذر تحميل المنشورات', false);
    }
  }

  void _startEdit(AdminPost post) {
    _editTitleCtrl.text = post.title;
    _editDescCtrl.text = post.description;
    _editType = post.type;
    _editImageFile = null;
    setState(() => _editing = post);
    // تمرير لأعلى
  }

  void _cancelEdit() => setState(() => _editing = null);

  Future<void> _saveEdit() async {
    if (_editTitleCtrl.text.trim().isEmpty) {
      _show('يرجى إدخال العنوان', false);
      return;
    }
    setState(() => _saving = true);

    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiEdit));
      req.fields['post_id'] = _editing!.id;
      req.fields['title'] = _editTitleCtrl.text.trim();
      req.fields['description'] =
          _editType == 'normal' ? _editDescCtrl.text.trim() : '';
      req.fields['type'] = _editType;

      if (_editImageFile != null) {
        req.files.add(
            await http.MultipartFile.fromPath('image', _editImageFile!.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);

      if (json['success'] == true) {
        _show('✅ تم التعديل بنجاح', true);
        setState(() => _editing = null);
        _fetchPosts();
      } else {
        _show('❌ ${json['message'] ?? 'حدث خطأ'}', false);
      }
    } catch (_) {
      _show('❌ تعذر الاتصال بالخادم', false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePost(AdminPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(isDark: widget.isDark, title: post.title),
    );
    if (confirmed != true) return;

    try {
      final res = await http.post(
        Uri.parse(_apiDelete),
        body: {'post_id': post.id},
      );
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        _show('🗑️ تم الحذف بنجاح', true);
        _fetchPosts();
      } else {
        _show('❌ فشل الحذف', false);
      }
    } catch (_) {
      _show('❌ تعذر الاتصال بالخادم', false);
    }
  }

  void _show(String msg, bool ok) {
    setState(() {
      _msg = msg;
      _success = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: _fetchPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── رسالة الحالة ──
            if (_msg != null) ...[
              _StatusBanner(
                  message: _msg!, success: _success, isDark: widget.isDark),
              const SizedBox(height: 14),
            ],

            // ── نموذج التعديل ──
            if (_editing != null) ...[
              _EditForm(
                post: _editing!,
                isDark: widget.isDark,
                titleCtrl: _editTitleCtrl,
                descCtrl: _editDescCtrl,
                type: _editType,
                imageFile: _editImageFile,
                saving: _saving,
                onTypeChanged: (v) => setState(() => _editType = v),
                onPickImage: () async {
                  final p = ImagePicker();
                  final f = await p.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (f != null) setState(() => _editImageFile = f);
                },
                onSave: _saveEdit,
                onCancel: _cancelEdit,
              ),
              const SizedBox(height: 20),
            ],

            // ── رأس القائمة ──
            Row(
              children: [
                Icon(Icons.dashboard_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text(
                  'جميع المنشورات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '${_posts.length}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchPosts,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── القائمة ──
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              )
            else if (_posts.isEmpty)
              _EmptyState(isDark: widget.isDark)
            else
              ...(_posts.map((p) => _PostCard(
                    post: p,
                    isDark: widget.isDark,
                    onEdit: () => _startEdit(p),
                    onDelete: () => _deletePost(p),
                  ))),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// بطاقة منشور في قائمة التعديل
// ────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final AdminPost post;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (post.type) {
      case 'file':
        return 'تطبيق';
      case 'simple':
        return 'سكربت';
      default:
        return 'منشور';
    }
  }

  Color get _typeColor {
    switch (post.type) {
      case 'file':
        return Colors.blue;
      case 'simple':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── صورة مصغرة ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: SizedBox(
              width: 88,
              height: 88,
              child: post.imageUrl.isNotEmpty
                  ? Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImg(isDark),
                    )
                  : _placeholderImg(isDark),
            ),
          ),

          // ── المعلومات ──
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.description,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── أزرار الإجراءات ──
          Column(
            children: [
              _ActionBtn(
                icon: Icons.edit_rounded,
                color: Colors.blue,
                onTap: onEdit,
              ),
              Container(
                height: 0.5,
                width: 48,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _ActionBtn(
                icon: Icons.delete_rounded,
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderImg(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded,
            color: Colors.grey, size: 28),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// نموذج التعديل
// ────────────────────────────────────────────────────────────
class _EditForm extends StatelessWidget {
  final AdminPost post;
  final bool isDark;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final XFile? imageFile;
  final bool saving;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditForm({
    required this.post,
    required this.isDark,
    required this.titleCtrl,
    required this.descCtrl,
    required this.type,
    required this.imageFile,
    required this.saving,
    required this.onTypeChanged,
    required this.onPickImage,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      borderColor: Colors.blue.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس النموذج
          Row(
            children: [
              const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تعديل: ${post.title}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // نوع المنشور
          _FieldLabel('نوع المنشور', Icons.category_rounded, isDark),
          const SizedBox(height: 8),
          _TypeSelector(selected: type, isDark: isDark, onChanged: onTypeChanged),
          const SizedBox(height: 14),

          // العنوان
          _FieldLabel('العنوان', Icons.title_rounded, isDark),
          const SizedBox(height: 8),
          _AppTextField(
              controller: titleCtrl, hint: 'العنوان', isDark: isDark),
          const SizedBox(height: 14),

          // الوصف
          if (type == 'normal') ...[
            _FieldLabel('الوصف', Icons.notes_rounded, isDark),
            const SizedBox(height: 8),
            _AppTextField(
              controller: descCtrl,
              hint: 'الوصف',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
          ],

          // الصورة
          _FieldLabel('تغيير الصورة (اختياري)', Icons.image_rounded, isDark),
          const SizedBox(height: 8),
          _ImagePickerBox(
            file: imageFile,
            isDark: isDark,
            onTap: onPickImage,
            existingUrl: post.imageUrl,
          ),
          const SizedBox(height: 18),

          // أزرار
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _SubmitButton(
                  label: 'حفظ التعديلات',
                  icon: Icons.save_rounded,
                  loading: saving,
                  onTap: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// مكوّنات مشتركة
// ────────────────────────────────────────────────────────────

/// بطاقة قسم
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? borderColor;

  const _SectionCard({
    required this.isDark,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ??
              (isDark ? Colors.white12 : Colors.black.withOpacity(0.07)),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// تسمية الحقل
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const _FieldLabel(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// حقل نصي بتنسيق التطبيق
class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;

  const _AppTextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Tajawal',
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

/// اختيار نوع المنشور
class _TypeSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _TypeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      ('normal', 'منشور', Icons.article_rounded),
      ('file', 'تطبيق', Icons.android_rounded),
      ('simple', 'سكربت', Icons.code_rounded),
    ];

    return Row(
      children: types.map((t) {
        final isActive = selected == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.red.withOpacity(0.15)
                    : (isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.red.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    t.$3,
                    color: isActive
                        ? Colors.red
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.$2,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.red
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// اختيار الصورة
class _ImagePickerBox extends StatelessWidget {
  final XFile? file;
  final bool isDark;
  final VoidCallback onTap;
  final String? existingUrl;

  const _ImagePickerBox({
    required this.file,
    required this.isDark,
    required this.onTap,
    this.existingUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withOpacity(0.25),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(file!.path), fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'تغيير',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : existingUrl != null && existingUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(existingUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _emptyBox()),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'تغيير',
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : _emptyBox(),
      ),
    );
  }

  Widget _emptyBox() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            color: Colors.red.withOpacity(0.6), size: 32),
        const SizedBox(height: 8),
        Text(
          'اضغط لاختيار صورة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: Colors.red.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// اختيار ملف مرفق
class _FilePickerBox extends StatelessWidget {
  final XFile? file;
  final bool isDark;
  final VoidCallback onTap;

  const _FilePickerBox(
      {required this.file, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle_rounded : Icons.attach_file_rounded,
              color: file != null ? Colors.green : Colors.red.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file != null ? file!.name : 'اختر ملفاً للرفع...',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: file != null
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر الإرسال
class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1A14), Color(0xFFE53935)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// شريط الحالة (نجاح / خطأ)
class _StatusBanner extends StatelessWidget {
  final String message;
  final bool success;
  final bool isDark;

  const _StatusBanner(
      {required this.message, required this.success, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: success
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: success ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة قائمة فارغة
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: Colors.red.withOpacity(0.4), size: 48),
          const SizedBox(height: 12),
          Text(
            'لا توجد منشورات بعد',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

/// زر الإجراء (تعديل / حذف)
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 44,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// حوار تأكيد الحذف
class _ConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String title;

  const _ConfirmDialog({required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'حذف المنشور',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من حذف "$title"؟\nلا يمكن التراجع عن هذا الإجراء.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1A14), Color(0xFFE53935)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'حذف',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
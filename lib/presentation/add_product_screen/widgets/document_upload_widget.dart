import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DocumentUploadWidget extends StatefulWidget {
  final Function(List<String>) onDocumentsChanged;
  final List<String>? initialDocuments;
  final List<String>? initialDocumentUrls;

  const DocumentUploadWidget({
    super.key,
    required this.onDocumentsChanged,
    this.initialDocuments,
    this.initialDocumentUrls,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  List<String> _documents = [];
  List<String> _documentUrls = [];

  @override
  void initState() {
    super.initState();
    _documents = widget.initialDocuments ?? [];
    _documentUrls = widget.initialDocumentUrls ?? [];
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        // Handle file upload and get URLs
        for (PlatformFile file in result.files) {
          // Simulate document upload - replace with actual implementation
          final documentUrl = 'https://example.com/documents/${file.name}';
          _documents.add(file.name ?? 'document');
          _documentUrls.add(documentUrl);
        }

        // Notify parent with both documents and document_urls
        widget.onDocumentsChanged(_documentUrls);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking documents: $e')),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      if (index < _documents.length) _documents.removeAt(index);
      if (index < _documentUrls.length) _documentUrls.removeAt(index);
    });
    widget.onDocumentsChanged(_documentUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Document'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No documents uploaded',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add certificates, licenses, or other documents',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_documents.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _documents[index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeDocument(index),
                      icon: const Icon(Icons.close, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

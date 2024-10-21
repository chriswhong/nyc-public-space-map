import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:nyc_public_space_map/public_space_properties.dart';

class ReportIssueDrawer extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature;
  const ReportIssueDrawer({this.selectedFeature, super.key});

  @override
  _ReportIssueDrawerState createState() => _ReportIssueDrawerState();
}

class _ReportIssueDrawerState extends State<ReportIssueDrawer> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final String googleFormUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLSdeRW4c1k16zHkkN3XO25PuRjoGxgOszSNAGV5zcKy6a4Afxw/formResponse';
  final String idField = 'entry.495981289';
  final String issueField = 'entry.823964625';

  Future<void> _submitForm(String spaceId, String inputText) async {
    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
      Uri.parse(googleFormUrl),
      body: {
        idField: spaceId,
        issueField: inputText,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 302) {
      setState(() {
        _isSubmitted = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final String spaceName =
        widget.selectedFeature?.properties?.name ?? "this space";

    final String spaceId = widget.selectedFeature?.properties?.space_id ?? 'no_space_id';

    return Drawer(
      width: screenWidth, // Set full-width for the drawer
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context, 'Report an Issue'),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isSubmitted
                          ? const Center(
                              child: Text(
                                'Thanks for reporting! We will look into it and update the record as soon as possible. 😎',
                                style: TextStyle(
                                    fontSize: 18),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: 'Describe the issue you\'re seeing with our information about ', // Regular text
                                    children: [
                                      TextSpan(
                                        text: spaceName, // The space name
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold), // Bold style for spaceName
                                      ),
                                      const TextSpan(
                                        text: ':', // Regular colon
                                      ),
                                    ],
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _controller,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    // hintText: 'Enter your message',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _isSubmitting
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: () {
                                          if (_controller.text.isNotEmpty) {
                                            _submitForm(
                                              spaceId,
                                              _controller.text
                                              );
                                          }
                                        },
                                        child: const Text('Submit'),
                                      ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.times),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

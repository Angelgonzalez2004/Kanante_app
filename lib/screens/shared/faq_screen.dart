import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  final Map<String, List<Map<String, String>>> faqData;

  const FaqScreen({super.key, required this.faqData});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.faqData.keys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.faqData.keys.toList();

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7 * 255).toDouble()),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: categories.map((title) => Tab(text: title)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.map((category) {
                final qas = widget.faqData[category]!;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900.0), // Max width for content on large screens
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: qas.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          child: ExpansionTile(
                            title: Text(qas[index]['q']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            childrenPadding: const EdgeInsets.all(16.0),
                            expandedAlignment: Alignment.centerLeft,
                            children: [
                              Text(qas[index]['a']!),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

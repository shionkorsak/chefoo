import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location.dart';

class BaseLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const BaseLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  @override
  void initState() {
    super.initState();
    Provider.of<LocationService>(context, listen: false).getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LocationService>(context, listen: false)
                  .getCurrentLocation();
            },
          ),
        ],
      ),
      body: Consumer<LocationService>(
        builder: (context, locationService, child) {
          if (locationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (locationService.error != null) {
            return Center(child: Text(locationService.error!));
          }
          
          return widget.child;
        },
      ),
    );
  }
}
import 'package:chefoo/widgets/cards/restaurant_card_vertical.dart';

import '../../commons.dart';

class FavoriteList extends StatefulWidget {
  const FavoriteList({super.key});

  @override
  State<FavoriteList> createState() => _FavoriteListState();
}

class _FavoriteListState extends State<FavoriteList> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final provider = Provider.of<FavoritesProvider>(context, listen: false);
    if (provider.favorites.isEmpty && !provider.isLoading) {
      provider.loadFavorites();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        if (favoritesProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        final favorites = favoritesProvider.favorites.reversed
            .take(5)
            .toList()
            .reversed
            .toList();

        if (favorites.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No favorites yet.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: SizedBox(
                height: 225,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                            left: 13, right: 13, bottom: 20),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final place = favorites[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: RestaurantCardVertical(
                              place: place,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

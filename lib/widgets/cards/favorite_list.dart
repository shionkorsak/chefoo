import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';

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
        if(provider.favorites.isEmpty && !provider.isLoading) {
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

                final favorites = favoritesProvider.favorites;

                if (favorites.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No favorites yet.'),
                    );
                }

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        SizedBox(
                            height: 220,
                            child: RestaurantCardListHorizontal(
                                without: true,
                                places: favorites,
                                isLoading: false,
                            ),
                        ),
                    ],
                );
            },
        );
    }
}

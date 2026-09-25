import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/repositories.dart';
import 'domain/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final store = LocalStore(
    await Hive.openBox<String>('auth'),
    await Hive.openBox<String>('cache'),
  );
  final api = ApiClient(store);
  runApp(
    PulseboardApp(
      auth: AuthRepository(api, store),
      catalog: CatalogRepository(api, store),
    ),
  );
}

class PulseboardApp extends StatelessWidget {
  const PulseboardApp({super.key, required this.auth, required this.catalog});
  final AuthRepository auth;
  final CatalogRepository catalog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulseboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffe86a33)),
        scaffoldBackgroundColor: const Color(0xfff7f4ef),
      ),
      home: auth.isAuthenticated
          ? HomePage(auth: auth, catalog: catalog)
          : LoginPage(auth: auth, catalog: catalog),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.catalog});
  final AuthRepository auth;
  final CatalogRepository catalog;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(text: 'emilys');
  final password = TextEditingController(text: 'emilyspass');
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.login(username.text, password.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                HomePage(auth: widget.auth, catalog: widget.catalog),
          ),
        );
      }
    } on AppFailure catch (failure) {
      setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 52,
                  color: Color(0xffe86a33),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bon retour.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Les signaux importants de ton équipe, réunis ici.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 32),
                if (error != null) _Notice(text: error!),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Démo : emilys / emilyspass',
                  style: TextStyle(color: Colors.black45),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const CircularProgressIndicator()
                        : const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.auth, required this.catalog});
  final AuthRepository auth;
  final CatalogRepository catalog;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final titles = const ['Vue d’ensemble', 'Articles', 'Équipe'];
  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductsPage(repository: widget.catalog),
      ArticlesPage(repository: widget.catalog),
      PeoplePage(repository: widget.catalog),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginPage(auth: widget.auth, catalog: widget.catalog),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Équipe',
          ),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key, required this.repository});
  final CatalogRepository repository;
  @override
  Widget build(BuildContext context) => AsyncSection<Product>(
    future: repository.products(),
    title: 'Catalogue',
    subtitle: 'Les produits suivis par ton équipe.',
    builder: (items) => GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 220,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => ProductCard(item: items[i]),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item});
  final Product item;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                item.thumbnail,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: Color(0xffeee8df),
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '${item.price.toStringAsFixed(0)} EUR  -  ${item.rating.toStringAsFixed(1)}',
            ),
          ),
        ],
      ),
    );
  }
}

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key, required this.repository});
  final CatalogRepository repository;
  @override
  Widget build(BuildContext context) => AsyncSection<Article>(
    future: repository.articles(),
    title: 'Brief du jour',
    subtitle: 'Les dernières idées partagées par la communauté.',
    builder: (items) => ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Text(
                  '${item.tags.join(' - ')}  |  ${item.views} vues',
                  style: const TextStyle(
                    color: Color(0xffe86a33),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key, required this.repository});
  final CatalogRepository repository;
  @override
  Widget build(BuildContext context) => AsyncSection<Person>(
    future: repository.people(),
    title: 'Ton équipe',
    subtitle: 'Les profils actifs dans l’espace.',
    builder: (items) => ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(item.name.substring(0, 1))),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.email),
          ),
        );
      },
    ),
  );
}

class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.future,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
  final Future<List<T>> future;
  final String title;
  final String subtitle;
  final Widget Function(List<T>) builder;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _Notice(
              text: snapshot.error.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Expanded(child: builder(snapshot.data ?? [])),
        ],
      );
    },
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: const Color(0xffffe6df),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Color(0xffb6462b)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xff8d3521))),
        ),
      ],
    ),
  );
}

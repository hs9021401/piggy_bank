import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'blocs/transaction/transaction_bloc.dart';
import 'blocs/transaction/transaction_event.dart';
import 'blocs/category/category_bloc.dart';
import 'blocs/category/category_event.dart';
import 'blocs/wallet/wallet_bloc.dart';
import 'blocs/wallet/wallet_event.dart';
import 'screens/main_screen.dart';
import 'screens/lock_screen.dart';

class DataRefreshNotifier extends ChangeNotifier {
  int _version = 0;
  
  void refresh() {
    _version++;
    notifyListeners();
  }
  
  int get version => _version;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  
  await DatabaseService.instance.processPeriodicTransactions();
  
  final prefs = await SharedPreferences.getInstance();
  final passwordEnabled = prefs.getBool('password_enabled') ?? false;
  
  runApp(PiggyBankApp(passwordEnabled: passwordEnabled));
}

class PiggyBankApp extends StatefulWidget {
  final bool passwordEnabled;
  
  const PiggyBankApp({super.key, required this.passwordEnabled});

  @override
  State<PiggyBankApp> createState() => _PiggyBankAppState();
}

class _PiggyBankAppState extends State<PiggyBankApp> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  final DataRefreshNotifier _refreshNotifier = DataRefreshNotifier();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isUnlocked = !widget.passwordEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (widget.passwordEnabled) {
        setState(() {
          _isUnlocked = false;
        });
      }
    }
  }

  void _unlock() {
    setState(() {
      _isUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService.instance;

    if (widget.passwordEnabled && !_isUnlocked) {
      return MaterialApp(
        title: '小豬公',
        debugShowCheckedModeBanner: false,
        home: LockScreen(onUnlock: _unlock),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TransactionBloc(databaseService)..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (_) => CategoryBloc(databaseService)..add(const LoadCategories()),
        ),
        BlocProvider(
          create: (_) => WalletBloc(databaseService)..add(LoadWallets()),
        ),
      ],
      child: MaterialApp(
        title: '小豬公',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6BCB77),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: ListenableBuilder(
          listenable: _refreshNotifier,
          builder: (context, _) {
            return MainScreen(
              key: ValueKey(_refreshNotifier.version),
              refreshNotifier: _refreshNotifier,
            );
          },
        ),
      ),
    );
  }
}

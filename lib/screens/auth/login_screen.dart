import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../models/merchant_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Merchant Log In',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const TabBar(
                tabs: [
                  Tab(text: 'Supervisor'),
                  Tab(text: 'Cashier'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _SupervisorLoginForm(),
                    _CashierLoginForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupervisorLoginForm extends StatefulWidget {
  const _SupervisorLoginForm();

  @override
  State<_SupervisorLoginForm> createState() => _SupervisorLoginFormState();
}

class _SupervisorLoginFormState extends State<_SupervisorLoginForm> {
  final _crController = TextEditingController();
  final _pinController = TextEditingController();
  final FocusNode _crFocusNode = FocusNode();
  
  bool _obscurePin = true;
  bool _isLoading = false;

  List<String> _savedCRNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCRNumbers();
  }

  Future<void> _loadSavedCRNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedCRNumbers = prefs.getStringList('saved_cr_numbers') ?? [];
    });
  }

  Future<void> _saveCRNumber(String cr) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_savedCRNumbers.contains(cr)) {
      _savedCRNumbers.add(cr);
      await prefs.setStringList('saved_cr_numbers', _savedCRNumbers);
    }
  }

  Future<void> _login() async {
    final cr = _crController.text.trim();
    final pin = _pinController.text.trim();

    if (cr.isEmpty || pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid CR Number and 4-digit PIN')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final userCredential = await authService.loginSupervisor(crNumber: cr, pin: pin);

      await _saveCRNumber(cr);

      if (userCredential.user != null) {
        final merchantUser = await authService.getMerchantUser(userCredential.user!);
        
        if (!mounted) return;

        if (merchantUser?.role == MerchantRole.unauthorized) {
          await authService.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access Denied: You do not have Merchant or Cashier privileges.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login Failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _crController.dispose();
    _pinController.dispose();
    _crFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          RawAutocomplete<String>(
            textEditingController: _crController,
            focusNode: _crFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return _savedCRNumbers;
              }
              return _savedCRNumbers.where((option) => option.contains(textEditingValue.text));
            },
            onSelected: (String selection) {
              _crController.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return CustomTextField(
                controller: controller,
                focusNode: focusNode,
                hintText: 'Enter your CR Number',
                keyboardType: TextInputType.text,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _pinController,
            hintText: 'Enter 4-digit PIN',
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 4,
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Login',
            isLoading: _isLoading,
            onPressed: _login,
          ),
        ],
      ),
    );
  }
}

class _CashierLoginForm extends StatefulWidget {
  const _CashierLoginForm();

  @override
  State<_CashierLoginForm> createState() => _CashierLoginFormState();
}

class _CashierLoginFormState extends State<_CashierLoginForm> {
  final _crController = TextEditingController();
  final _counterController = TextEditingController();
  final _employeeController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _crFocusNode = FocusNode();
  final FocusNode _counterFocusNode = FocusNode();
  final FocusNode _employeeFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  List<String> _savedCRNumbers = [];
  List<String> _savedCounterNumbers = [];
  List<String> _savedEmployeeNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFields();
  }

  Future<void> _loadSavedFields() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedCRNumbers = prefs.getStringList('saved_cashier_cr_numbers') ?? [];
      _savedCounterNumbers = prefs.getStringList('saved_cashier_counter_numbers') ?? [];
      _savedEmployeeNumbers = prefs.getStringList('saved_cashier_employee_numbers') ?? [];
    });
  }

  Future<void> _saveFields(String cr, String counter, String employee) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!_savedCRNumbers.contains(cr)) {
      _savedCRNumbers.add(cr);
      await prefs.setStringList('saved_cashier_cr_numbers', _savedCRNumbers);
    }
    if (!_savedCounterNumbers.contains(counter)) {
      _savedCounterNumbers.add(counter);
      await prefs.setStringList('saved_cashier_counter_numbers', _savedCounterNumbers);
    }
    if (!_savedEmployeeNumbers.contains(employee)) {
      _savedEmployeeNumbers.add(employee);
      await prefs.setStringList('saved_cashier_employee_numbers', _savedEmployeeNumbers);
    }
  }

  Future<void> _login() async {
    final cr = _crController.text.trim();
    final counter = _counterController.text.trim();
    final employee = _employeeController.text.trim();
    final password = _passwordController.text.trim();

    if (cr.isEmpty || counter.isEmpty || employee.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final userCredential = await authService.loginCashier(
        crNumber: cr,
        employeeNumber: employee,
        password: password,
      );

      await _saveFields(cr, counter, employee);

      if (mounted && userCredential.user != null) {
        final merchantUser = await authService.getMerchantUser(userCredential.user!);
        
        if (!mounted) return;

        if (merchantUser?.role == MerchantRole.unauthorized) {
          await authService.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access Denied: You do not have Cashier privileges.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login Failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _crController.dispose();
    _counterController.dispose();
    _employeeController.dispose();
    _passwordController.dispose();
    _crFocusNode.dispose();
    _counterFocusNode.dispose();
    _employeeFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required List<String> optionsList,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return optionsList;
        }
        return optionsList.where((option) => option.contains(textEditingValue.text));
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return CustomTextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          hintText: hintText,
          keyboardType: keyboardType,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildAutocompleteField(
            controller: _crController,
            focusNode: _crFocusNode,
            hintText: 'Merchant CR Number',
            optionsList: _savedCRNumbers,
          ),
          const SizedBox(height: 16),
          _buildAutocompleteField(
            controller: _counterController,
            focusNode: _counterFocusNode,
            hintText: 'Cashier Counter Number',
            optionsList: _savedCounterNumbers,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildAutocompleteField(
            controller: _employeeController,
            focusNode: _employeeFocusNode,
            hintText: 'Employee Number',
            optionsList: _savedEmployeeNumbers,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Enter Password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Login',
            isLoading: _isLoading,
            onPressed: _login,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  // Controllers for everyone
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // --- NEW: Controllers for Doctors ---
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _feesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLogin = true; // Toggle between Login and Sign Up
  bool _isDoctor = false; // --- NEW: Toggle for Doctor Signup ---
  String _errorMessage = '';

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _isDoctor = false; // Reset doctor check on form toggle
      _errorMessage = '';
    });
  }

  void _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
      });
      return;
    }

    if (_isLogin) {
      // --- LOGIN ---
      final userCredential =
          await _authService.signInWithEmail(email, password);
      if (userCredential == null) {
        setState(() {
          _errorMessage = "Login failed. Please check your credentials.";
        });
      }
    } else {
      // --- SIGN UP ---
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final role = _isDoctor ? 'doctor' : 'patient';

      if (firstName.isEmpty || lastName.isEmpty) {
        setState(() {
          _errorMessage = "Please fill in all fields.";
        });
        return;
      }

      // --- NEW: Prepare Doctor Data ---
      Map<String, dynamic>? doctorData;
      if (_isDoctor) {
        final specialty = _specialtyController.text.trim();
        final qualification = _qualificationController.text.trim();
        final fees = double.tryParse(_feesController.text.trim()) ?? 0.0;
        final location = _locationController.text.trim();

        if (specialty.isEmpty || qualification.isEmpty || location.isEmpty) {
          setState(() {
            _errorMessage = "Please fill in all doctor fields.";
          });
          return;
        }

        doctorData = {
          'specialty': specialty,
          'qualification': qualification,
          'consultationFee': fees,
          'clinicAddress': location,
          'title': 'Dr.', // Default title
          'bio': '', // Default empty bio
        };
      }

      // --- Call the updated signup function ---
      final userCredential = await _authService.signUpWithEmail(
        email,
        password,
        firstName,
        lastName,
        role,
        doctorData: doctorData, // Pass the extra data
      );

      if (userCredential == null) {
        setState(() {
          _errorMessage = "Sign up failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // Good for web/tablet layout
            ),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/mediconnect_logo.png',
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Join MediConnect',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                    Text(
                      _isLogin
                          ? 'Login to your account'
                          : 'Create a new account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 32),

                    // --- SIGN UP FIELDS (conditional) ---
                    if (!_isLogin) ...[
                      TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- COMMON FIELDS ---
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // --- NEW: DOCTOR CHECKBOX ---
                    if (!_isLogin)
                      CheckboxListTile(
                        title: const Text("Sign up as a Doctor"),
                        value: _isDoctor,
                        onChanged: (newValue) {
                          setState(() {
                            _isDoctor = newValue ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).primaryColor,
                      ),

                    // --- NEW: DOCTOR FIELDS (conditional & animated) ---
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin && _isDoctor) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            Text(
                              "Doctor's Profile",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _specialtyController,
                              decoration: const InputDecoration(
                                labelText: 'Specialty (e.g., Cardiologist)',
                                prefixIcon:
                                    Icon(Icons.medical_services_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _qualificationController,
                              decoration: const InputDecoration(
                                labelText: 'Qualification (e.g., MBBS, MD)',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _feesController,
                              decoration: const InputDecoration(
                                labelText: 'Consultation Fee',
                                prefixIcon: Icon(Icons.attach_money_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Clinic Address',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),

                    // --- ERROR MESSAGE ---
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // --- SUBMIT BUTTON ---
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                    const SizedBox(height: 16),

                    // --- TOGGLE BUTTON ---
                    TextButton(
                      onPressed: _toggleForm,
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

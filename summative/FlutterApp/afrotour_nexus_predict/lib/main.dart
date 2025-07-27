import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tourism Prediction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _tourismReceiptsController = TextEditingController();
  final TextEditingController _tourismExportsController = TextEditingController();
  final TextEditingController _tourismExpendituresController = TextEditingController();
  final TextEditingController _gdpController = TextEditingController();
  final TextEditingController _inflationController = TextEditingController();
  final TextEditingController _unemploymentController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _predictionResult = '';
  bool _isLoading = false;

  final String _apiEndpoint = 'https://aftnx-ml-prediction-model.onrender.com/predict';

  @override
  void dispose() {
    _countryController.dispose();
    _yearController.dispose();
    _tourismReceiptsController.dispose();
    _tourismExportsController.dispose();
    _tourismExpendituresController.dispose();
    _gdpController.dispose();
    _inflationController.dispose();
    _unemploymentController.dispose();
    super.dispose();
  }

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _predictionResult = 'Please fix the errors in the form.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = 'Predicting...';
    });

    final Map<String, dynamic> requestBody = {
      'country': _countryController.text,
      'year': int.tryParse(_yearController.text),
      'tourism_receipts': double.tryParse(_tourismReceiptsController.text),
      'tourism_exports': double.tryParse(_tourismExportsController.text),
      'tourism_expenditures': double.tryParse(_tourismExpendituresController.text),
      'gdp': double.tryParse(_gdpController.text),
      'inflation': double.tryParse(_inflationController.text),
      'unemployment': _unemploymentController.text.isEmpty
          ? null
          : double.tryParse(_unemploymentController.text),
    };

    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _predictionResult = 'Predicted Arrivals: ${data['predicted_tourism_arrivals'].toStringAsFixed(0)}';
        });
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        setState(() {
          _predictionResult = 'Error: ${errorData['detail'] ?? 'Unknown API error'} (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Network Error: $e. Please check your internet connection and API URL.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourism Arrivals Prediction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/ankara_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Color.fromARGB((0.55 * 255).round(), 0, 0, 0),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Text(
                    'Predict Tourism Arrivals',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Color.fromARGB((0.5 * 255).round(), 0, 0, 0),
                            offset: const Offset(2.0, 2.0),
                          ),
                        ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Card(
                    color: Color.fromARGB((0.92 * 255).round(), 255, 255, 255),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _countryController,
                            labelText: 'Country',
                            hintText: 'e.g., South Africa',
                            icon: Icons.flag,
                            validator: (value) => value == null || value.isEmpty ? 'Country is required' : null,
                          ),
                          _buildTextField(
                            controller: _yearController,
                            labelText: 'Year',
                            hintText: 'e.g., 2023',
                            keyboardType: TextInputType.number,
                            icon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Year is required';
                              final year = int.tryParse(value);
                              if (year == null || year < 1999 || year > 2100) return 'Enter a year between 1999 and 2100';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _tourismReceiptsController,
                            labelText: 'Tourism Receipts (LCU)',
                            hintText: 'e.g., 150000000.0',
                            keyboardType: TextInputType.number,
                            icon: Icons.receipt_long,
                            validator: (value) => _validateDouble(value, 'Tourism Receipts'),
                          ),
                          _buildTextField(
                            controller: _tourismExportsController,
                            labelText: 'Tourism Exports (%)',
                            hintText: 'e.g., 5.5',
                            keyboardType: TextInputType.number,
                            icon: Icons.trending_up,
                            validator: (value) => _validateDouble(value, 'Tourism Exports'),
                          ),
                          _buildTextField(
                            controller: _tourismExpendituresController,
                            labelText: 'Tourism Expenditures (%)',
                            hintText: 'e.g., 3.0',
                            keyboardType: TextInputType.number,
                            icon: Icons.trending_down,
                            validator: (value) => _validateDouble(value, 'Tourism Expenditures'),
                          ),
                          _buildTextField(
                            controller: _gdpController,
                            labelText: 'GDP (LCU)',
                            hintText: 'e.g., 10000000000.0',
                            keyboardType: TextInputType.number,
                            icon: Icons.monetization_on,
                            validator: (value) => _validateDouble(value, 'GDP'),
                          ),
                          _buildTextField(
                            controller: _inflationController,
                            labelText: 'Inflation (%)',
                            hintText: 'e.g., 5.0',
                            keyboardType: TextInputType.number,
                            icon: Icons.price_change,
                            validator: (value) => _validateDouble(value, 'Inflation'),
                          ),
                          _buildTextField(
                            controller: _unemploymentController,
                            labelText: 'Unemployment (%) (Optional)',
                            hintText: 'e.g., 7.5',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final val = double.tryParse(value);
                                if (val == null || val < 0 || val > 100) {
                                  return 'Must be a number between 0-100';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _makePrediction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blueAccent.shade700,
                            foregroundColor: Colors.white,
                            elevation: 8,
                          ),
                          child: const Text(
                            'Predict Tourism Arrivals',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color.fromARGB((0.92 * 255).round(), 255, 255, 255),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.shade100, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB((0.2 * 255).round(), 0, 0, 0),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _predictionResult.isEmpty ? 'Enter values and click "Predict"' : _predictionResult,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _predictionResult.startsWith('Error') || _predictionResult.startsWith('Network Error')
                              ? Colors.red.shade700
                              : Colors.blue.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent.shade700) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  String? _validateDouble(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return 'Enter a valid positive number for $fieldName';
    }
    return null;
  }
}
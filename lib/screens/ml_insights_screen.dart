import 'package:flutter/material.dart';
import '../models/ml_models.dart';
import '../models/transaction.dart';
import '../services/enhanced_ml_service.dart';
import '../l10n/app_localizations.dart';

class MLInsightsScreen extends StatefulWidget {
  const MLInsightsScreen({Key? key}) : super(key: key);

  @override
  State<MLInsightsScreen> createState() => _MLInsightsScreenState();
}

class _MLInsightsScreenState extends State<MLInsightsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  List<AnomalyAlert> _anomalies = [];
  CashflowForecast? _forecast;
  List<PersonalizedAdvice> _advice = [];
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMLData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMLData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        EnhancedMLService.getAnomalyAlerts(),
        EnhancedMLService.getCashflowForecast(),
        EnhancedMLService.getPersonalizedAdvice(),
      ]);
      
      setState(() {
        _anomalies = results[0] as List<AnomalyAlert>;
        final forecastList = results[1] as List<CashflowForecast>;
        _forecast = forecastList.isNotEmpty ? forecastList.first : null;
        _advice = results[2] as List<PersonalizedAdvice>;
        _summary = {
          'totalAnomalies': _anomalies.length,
          'forecastAccuracy': 0.85,
          'adviceCount': _advice.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ML insights: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 ML Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Anomalies'),
            Tab(icon: Icon(Icons.trending_up), text: 'Forecast'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Advice'),
            Tab(icon: Icon(Icons.dashboard), text: 'Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMLData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnomaliesTab(),
                _buildForecastTab(),
                _buildAdviceTab(),
                _buildSummaryTab(),
              ],
            ),
    );
  }

  Widget _buildAnomaliesTab() {
    if (_anomalies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No anomalies detected', style: TextStyle(fontSize: 18)),
            Text('Your spending patterns look normal'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = _anomalies[index];
        return _buildAnomalyCard(anomaly);
      },
    );
  }

  Widget _buildAnomalyCard(AnomalyAlert anomaly) {
    Color severityColor;
    IconData severityIcon;
    
    switch (anomaly.severity) {
      case AnomalySeverity.critical:
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case AnomalySeverity.high:
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case AnomalySeverity.medium:
        severityColor = Colors.yellow.shade700;
        severityIcon = Icons.info;
        break;
      case AnomalySeverity.low:
        severityColor = Colors.blue;
        severityIcon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor),
                const SizedBox(width: 8),
                Text(
                  '${anomaly.type.toString().split('.').last} Spending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    '${(anomaly.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${anomaly.transaction.amount.toStringAsFixed(2)} - ${anomaly.transaction.description}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Expected range: \$${anomaly.expectedRange}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Date: ${anomaly.transaction.date.toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTab() {
    if (_forecast == null) {
      return const Center(
        child: Text('No forecast data available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_forecast!.currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      color: _forecast!.currentBalance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Risk Level: ${_forecast!.riskLevel.toString().split('.').last}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getRiskLevelColor(_forecast!.riskLevel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_forecast!.recommendations.isNotEmpty) ...[
            Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._forecast!.recommendations.map((rec) => Card(
              child: ListTile(
                leading: Icon(Icons.lightbulb, color: Colors.amber),
                title: Text(rec),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdviceTab() {
    if (_advice.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No advice available', style: TextStyle(fontSize: 18)),
            Text('Keep using the app to get personalized insights'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _advice.length,
      itemBuilder: (context, index) {
        final advice = _advice[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(advice.description),
                if (advice.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Handle advice action
                    },
                    child: const Text('View Actions'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    if (_summary == null) {
      return const Center(
        child: Text('No summary data available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ML Analysis Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryItem(
                    'Anomalies Detected',
                    '${_summary!['totalAnomalies']}',
                    Icons.warning,
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildSummaryItem(
                    'Forecast Accuracy',
                    '${(_summary!['forecastAccuracy'] * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildSummaryItem(
                    'Personalized Advice',
                    '${_summary!['adviceCount']} items',
                    Icons.lightbulb,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }
}
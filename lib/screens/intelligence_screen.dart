import 'package:flutter/material.dart';
import '../models/financial_intelligence.dart';
import '../services/intelligence_service.dart';
import '../services/web_storage_service.dart';
import 'ml_insights_screen.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({Key? key}) : super(key: key);

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  bool _isLoading = true;
  List<FinancialInsight> _insights = [];
  FinancialHealthMetrics? _healthMetrics;
  List<SpendingPrediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    _loadIntelligenceData();
  }

  Future<void> _loadIntelligenceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        IntelligenceService.getLatestInsights(),
        IntelligenceService.getFinancialHealth(),
        IntelligenceService.getSpendingPredictions(),
      ]);

      setState(() {
        _insights = results[0] as List<FinancialInsight>;
        _healthMetrics = results[1] as FinancialHealthMetrics?;
        _predictions = results[2] as List<SpendingPrediction>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading intelligence data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIntelligenceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_healthMetrics != null) _buildHealthMetricsCard(),
                    const SizedBox(height: 16),
                    _buildQuickInsights(),
                    const SizedBox(height: 16),
                    _buildAdvancedAnalysisCard(),
                    const SizedBox(height: 16),
                    if (_predictions.isNotEmpty) _buildPredictionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthMetricsCard() {
    final score = _healthMetrics!.overallScore;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getScoreIcon(score),
                  color: _getHealthScoreColor(score),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getHealthScoreColor(score),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getHealthScoreColor(score)),
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Savings Rate',
                    '${(_healthMetrics!.savingsRate * 100).toStringAsFixed(1)}%',
                    Icons.savings,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Expense Variability',
                    '${(_healthMetrics!.expenseVariability * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    final actionableInsights = _insights.where((i) => i.actionable).take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        ...actionableInsights.map((insight) => Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getInsightTypeColor(insight.type),
              child: Icon(
                _getInsightTypeIcon(insight.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(insight.title),
            subtitle: Text(insight.description),
            trailing: Text(
              '${(insight.confidence * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildAdvancedAnalysisCard() {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MLInsightsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.purple[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Advanced ML Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get deeper insights with machine learning analysis, anomaly detection, and personalized recommendations.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFeatureChip('Anomaly Detection', Icons.warning_amber),
                  const SizedBox(width: 8),
                  _buildFeatureChip('Smart Predictions', Icons.trending_up),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFeatureChip('Cashflow Forecast', Icons.account_balance),
                  const SizedBox(width: 8),
                  _buildFeatureChip('Personal Advice', Icons.lightbulb),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.purple[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Predictions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._predictions.take(3).map((prediction) => FutureBuilder<String>(
              future: _getCategoryName(prediction.categoryId),
              builder: (context, snapshot) {
                final categoryName = snapshot.data ?? prediction.categoryId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Predicted: \$${prediction.predictedAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(prediction.confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<String> _getCategoryName(String categoryId) async {
    try {
      final categories = await WebStorageService.getCategories();
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      );
      return category.name;
    } catch (e) {
      return categoryId; // Fallback to ID if category not found
    }
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.sentiment_very_satisfied;
    if (score >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Color _getInsightTypeColor(InsightType type) {
    switch (type) {
      case InsightType.recommendation:
        return Colors.blue;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.achievement:
        return Colors.green;
      case InsightType.anomaly:
        return Colors.red;
      case InsightType.pattern:
        return Colors.purple;
      case InsightType.opportunity:
        return Colors.teal;
    }
  }

  IconData _getInsightTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.recommendation:
        return Icons.lightbulb;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.achievement:
        return Icons.star;
      case InsightType.anomaly:
        return Icons.error;
      case InsightType.pattern:
        return Icons.trending_up;
      case InsightType.opportunity:
        return Icons.flag;
    }
  }
}
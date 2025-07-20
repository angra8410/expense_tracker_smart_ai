// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Rastreador Inteligente de Gastos con IA';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transacciones';

  @override
  String get categories => 'Categories';

  @override
  String get settings => 'Configuración';

  @override
  String get analytics => 'Análisis';

  @override
  String get home => 'Inicio';

  @override
  String get add => 'Agregar';

  @override
  String get aiInsights => 'Insights de IA';

  @override
  String get testing => 'Pruebas';

  @override
  String get addTransaction => 'Agregar Transacción';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get transactionAdded => 'Transaction added successfully!';

  @override
  String get transactionUpdated => 'Transaction updated successfully!';

  @override
  String get transactionDeleted => 'Transaction deleted successfully!';

  @override
  String get confirmDeleteTransaction =>
      'Are you sure you want to delete this transaction?';

  @override
  String get confirmDeleteTransactionMessage => 'This action cannot be undone.';

  @override
  String get amount => 'Cantidad';

  @override
  String get description => 'Descripción';

  @override
  String get category => 'Categoría';

  @override
  String get date => 'Fecha';

  @override
  String get type => 'Type';

  @override
  String get expense => 'Gasto';

  @override
  String get income => 'Ingreso';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get selectCategory => 'Seleccionar una categoría';

  @override
  String get selectDate => 'Select Date';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get pleaseEnterAmount => 'Por favor ingresa una cantidad';

  @override
  String get pleaseEnterDescription => 'Por favor ingresa una descripción';

  @override
  String get pleaseSelectCategory => 'Por favor selecciona una categoría';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get pleaseEnterValidAmount => 'Por favor ingresa una cantidad válida';

  @override
  String get totalIncome => 'Ingresos Totales';

  @override
  String get totalExpenses => 'Gastos Totales';

  @override
  String get balance => 'Balance';

  @override
  String get netBalance => 'Balance Neto';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsYet => 'Aún no hay transacciones';

  @override
  String get addFirstTransaction =>
      'Agrega tu primera transacción o genera datos de prueba';

  @override
  String get recentTransactions => '📊 Transacciones Recientes';

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryAdded => 'Category added successfully!';

  @override
  String get categoryUpdated => 'Category updated successfully!';

  @override
  String get categoryDeleted => 'Category deleted successfully!';

  @override
  String get confirmDeleteCategory =>
      'Are you sure you want to delete this category?';

  @override
  String get confirmDeleteCategoryMessage =>
      'This action cannot be undone. All transactions in this category will be moved to \'Other\'.';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryIcon => 'Category Icon';

  @override
  String get categoryColor => 'Category Color';

  @override
  String get pleaseEnterCategoryName => 'Please enter a category name';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get addFirstCategory =>
      'Add your first category to organize your transactions';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Idioma';

  @override
  String get currency => 'Moneda';

  @override
  String get notifications => 'Notifications';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get confirmClearData => 'Are you sure you want to clear all data?';

  @override
  String get confirmClearDataMessage =>
      'This action cannot be undone. All your transactions, categories, and settings will be permanently deleted.';

  @override
  String get dataCleared => 'All data cleared successfully!';

  @override
  String get dataExported => 'Data exported successfully!';

  @override
  String get dataImported => 'Data imported successfully!';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get appearance => 'Apariencia';

  @override
  String get localization => 'Localización';

  @override
  String get chooseLanguage => 'Elige tu idioma';

  @override
  String get chooseCurrency => 'Elige tu moneda';

  @override
  String get chooseTheme => 'Elige tu tema';

  @override
  String get refreshData => 'Actualizar Datos';

  @override
  String get loadingCategories => 'Cargando categorías...';

  @override
  String readyTransactions(int count) {
    return '¡Listo! $count categorías cargadas';
  }

  @override
  String get coffee => 'Café';

  @override
  String get lunch => 'Almuerzo';

  @override
  String get gas => 'Gasolina';

  @override
  String get salary => 'Salario';

  @override
  String get grocery => 'Mercado';

  @override
  String get movie => 'Película';

  @override
  String get thisMonth => 'Este Mes';

  @override
  String get lastMonth => 'Mes Pasado';

  @override
  String get thisYear => 'Este Año';

  @override
  String get allTime => 'Todo el Tiempo';

  @override
  String get spendingOverview => 'Resumen de Gastos';

  @override
  String get categoryBreakdown => 'Desglose por Categoría';

  @override
  String get budgets => 'Presupuestos';

  @override
  String get budgetManagement => 'Gestión de Presupuestos';

  @override
  String get createBudget => 'Crear Presupuesto';

  @override
  String get editBudget => 'Editar Presupuesto';

  @override
  String get updateBudget => 'Actualizar Presupuesto';

  @override
  String get deleteBudget => 'Eliminar Presupuesto';

  @override
  String get budgetName => 'Nombre del Presupuesto';

  @override
  String get budgetPeriod => 'Período del Presupuesto';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get yearly => 'Anual';

  @override
  String get enableRollover => 'Habilitar Transferencia';

  @override
  String get rolloverDescription =>
      'El presupuesto no utilizado se transfiere al siguiente período';

  @override
  String get smartBudgetRecommendations =>
      'Recomendaciones Inteligentes de Presupuesto';

  @override
  String get budgetOverview => 'Resumen del Presupuesto';

  @override
  String get totalBudget => 'Presupuesto Total';

  @override
  String get totalSpent => 'Total Gastado';

  @override
  String get remaining => 'Restante';

  @override
  String get overallProgress => 'Progreso General';

  @override
  String get activeBudgets => 'Presupuestos Activos';

  @override
  String get noBudgetsYet => 'Aún no hay presupuestos';

  @override
  String get createFirstBudget =>
      'Crea tu primer presupuesto para comenzar a rastrear tus metas de gasto';

  @override
  String get spent => 'gastado';

  @override
  String get budgeted => 'presupuestado';

  @override
  String get used => 'usado';

  @override
  String get suggested => 'sugerido';

  @override
  String get pleaseEnterBudgetName =>
      'Por favor ingresa un nombre para el presupuesto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get create => 'Crear';

  @override
  String get update => 'Actualizar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get budgetCreated => '¡Presupuesto creado exitosamente!';

  @override
  String get budgetUpdated => '¡Presupuesto actualizado exitosamente!';

  @override
  String get budgetDeleted => '¡Presupuesto eliminado exitosamente!';

  @override
  String get confirmDeleteBudget =>
      '¿Estás seguro de que quieres eliminar este presupuesto?';

  @override
  String get confirmDeleteBudgetMessage =>
      'Esta acción no se puede deshacer. Todos los datos del presupuesto se eliminarán permanentemente.';

  @override
  String get onTrack => 'En Camino';

  @override
  String get warning => 'Advertencia';

  @override
  String get exceeded => 'Excedido';

  @override
  String get rolloverEnabled => 'Transferencia Habilitada';

  @override
  String get rolloverDisabled => 'Transferencia Deshabilitada';

  @override
  String budgetRolledOver(String amount) {
    return 'Presupuesto transferido con $amount restante';
  }

  @override
  String get aiAnalysis => 'Análisis de IA';

  @override
  String get aiAnalysisDescription =>
      'Insights inteligentes y patrones de gasto';

  @override
  String get aiAnalysisScore => 'Puntuación de Análisis de IA';

  @override
  String get errorLoadingData => 'Error al cargar datos';

  @override
  String get noCategoriesFound => 'No se encontraron categorías';

  @override
  String get debugControls => 'Controles de Depuración';

  @override
  String get testCompleted => 'Prueba completada';

  @override
  String get allDataCleared => 'Todos los datos eliminados';

  @override
  String get categoryFood => 'Comida y Restaurantes';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categoryEntertainment => 'Entretenimiento';

  @override
  String get categoryBills => 'Facturas y Servicios';

  @override
  String get categoryHealth => 'Salud y Fitness';

  @override
  String get categorySalary => 'Salario';

  @override
  String get categoryInvestment => 'Inversiones';

  @override
  String get categoryEducation => 'Educación';

  @override
  String get categoryGift => 'Regalos y Donaciones';

  @override
  String get categoryOther => 'Otros';

  @override
  String get smartCategoryPrediction => 'Predicción Inteligente de Categoría';

  @override
  String get anomalyDetection => 'Detección de Anomalías';

  @override
  String get cashflowForecast => 'Pronóstico de Flujo de Efectivo';

  @override
  String get personalizedAdvice => 'Consejos Personalizados';

  @override
  String get mlInsights => 'Insights de ML';

  @override
  String get unusualSpending => 'Gasto Inusual';

  @override
  String get spendingAnomaly => 'Anomalía de Gasto Detectada';

  @override
  String get forecastBalance => 'Saldo Pronosticado';

  @override
  String get predictedIncome => 'Ingresos Predichos';

  @override
  String get predictedExpenses => 'Gastos Predichos';

  @override
  String confidenceLevel(String confidence) {
    return 'Confianza: $confidence%';
  }

  @override
  String potentialSavings(String amount) {
    return 'Ahorros Potenciales: $amount';
  }

  @override
  String mlAccuracy(String accuracy) {
    return 'Precisión ML: $accuracy%';
  }

  @override
  String anomalyScore(String score) {
    return 'Puntuación de Anomalía: $score';
  }

  @override
  String expectedRange(String min, String max) {
    return 'Rango Esperado: $min - $max';
  }

  @override
  String forecastDays(String days) {
    return 'Pronóstico para $days días';
  }

  @override
  String adviceDifficulty(String difficulty) {
    return 'Dificultad: $difficulty';
  }

  @override
  String adviceTimeframe(String timeframe) {
    return 'Plazo: $timeframe';
  }

  @override
  String get mlFeatures => '🤖 Características ML';

  @override
  String get smartCategoryAssignment => 'Asignación Inteligente de Categoría';

  @override
  String get smartCategoryDesc =>
      'ML aprende tus patrones y sugiere categorías';

  @override
  String get anomalyAlertsDesc =>
      'Recibe alertas por patrones de gasto inusuales';

  @override
  String get cashflowForecastDesc => 'Predice saldos futuros de cuenta';

  @override
  String get personalizedAdviceDesc =>
      'Recomendaciones personalizadas basadas en tu comportamiento';

  @override
  String get enableMLFeatures => 'Habilitar Características ML';

  @override
  String get mlAnalysisRunning => 'Ejecutando Análisis ML...';

  @override
  String get mlAnalysisComplete => 'Análisis ML Completo';

  @override
  String get insufficientDataForML =>
      'Necesitas más transacciones para análisis ML';

  @override
  String get viewMLInsights => 'Ver Insights ML';

  @override
  String get anomalyAlerts => 'Alertas de Anomalías';

  @override
  String get noAnomaliesDetected => 'No se detectaron anomalías';

  @override
  String get forecastAccuracy => 'Precisión del Pronóstico';

  @override
  String get highConfidence => 'Alta Confianza';

  @override
  String get mediumConfidence => 'Confianza Media';

  @override
  String get lowConfidence => 'Baja Confianza';
}

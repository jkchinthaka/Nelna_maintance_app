class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  // vehicles
  static const String vehicles = '/vehicles';
  static const String vehicleReminders = '/vehicles/reminders';
  static const String vehicleFuelLogs = '/vehicles/fuel-logs';
  static const String vehicleDocuments = '/vehicles/documents';
  static const String vehicleAssignDriver = '/vehicles/assign-driver';
  // machines
  static const String machines = '/machines';
  static const String machineSchedules = '/machines/schedules';
  static const String machineBreakdowns = '/machines/breakdowns';
  static const String machineAMC = '/machines/amc';
  // services
  static const String services = '/services';
  static const String serviceTasks = '/services/tasks';
  static const String serviceSpareParts = '/services/spare-parts';
  // inventory
  static const String products = '/inventory/products';
  static const String categories = '/inventory/categories';
  static const String stockIn = '/inventory/stock-in';
  static const String stockOut = '/inventory/stock-out';
  static const String suppliers = '/inventory/suppliers';
  static const String purchaseOrders = '/inventory/purchase-orders';
  static const String grns = '/inventory/grns';
  // assets
  static const String assets = '/assets';
  static const String assetRepairs = '/assets/repairs';
  static const String assetTransfers = '/assets/transfers';
  // reports
  static const String dashboard = '/reports/dashboard';
  static const String reportVehicleCosts = '/reports/vehicle-costs';
  static const String reportMachineDowntime = '/reports/machine-downtime';
  static const String reportInventoryUsage = '/reports/inventory-usage';
  static const String reportExpenses = '/reports/expenses';
  static const String reportMonthlyTrends = '/reports/monthly-trends';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _budgetController =
      TextEditingController();

  bool _comfortMode = false;
  String _mode = 'balanced';

  bool _loading = true;
  bool _saving = false;
  bool _loadingSpending = true;

  double _monthlyBudget = 0;
  double _monthlySpent = 0;

  List<Map<String, dynamic>> _spendingHistory = [];

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMonthlySpending();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        final preferences = Map<String, dynamic>.from(
          data['preferences'] ?? {},
        );

        final budget = data['monthlyBudget'];

        _monthlyBudget = budget is num
            ? budget.toDouble()
            : double.tryParse(
                  budget?.toString() ?? '',
                ) ??
                0;

        _budgetController.text = _monthlyBudget > 0
            ? _monthlyBudget.toStringAsFixed(0)
            : '';

        _comfortMode = preferences['comfort'] == true;

        _mode = preferences['mode']?.toString() ?? 'balanced';
      }
    } catch (e) {
      _showMessage('Unable to load profile');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // LOAD CURRENT MONTH SPENDING
  // ============================================================

  Future<void> _loadMonthlySpending() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingSpending = false;
        });
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .get();

      final now = DateTime.now();

      final startOfMonth = DateTime(
        now.year,
        now.month,
        1,
      );

      final startOfNextMonth = DateTime(
        now.year,
        now.month + 1,
        1,
      );

      double total = 0;

      final List<Map<String, dynamic>> history = [];

      for (final document in snapshot.docs) {
        final data = document.data();

        final amountValue = data['amount'];

        final double amount = amountValue is num
            ? amountValue.toDouble()
            : double.tryParse(
                  amountValue?.toString() ?? '',
                ) ??
                0;

        DateTime? createdAt;

        final timestamp = data['createdAt'];

        if (timestamp is Timestamp) {
          createdAt = timestamp.toDate();
        }

        if (createdAt != null &&
            !createdAt.isBefore(startOfMonth) &&
            createdAt.isBefore(startOfNextMonth)) {
          total += amount;

          history.add({
            ...data,
            'id': document.id,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _monthlySpent = total;
        _spendingHistory = history;
        _loadingSpending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSpending = false;
      });

      _showMessage('Unable to load spending data');
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final user = _user;

    if (user == null) {
      _showMessage('Please login first');
      return;
    }

    final budgetText = _budgetController.text.trim();

    final budget = double.tryParse(budgetText);

    if (budgetText.isNotEmpty && budget == null) {
      _showMessage('Please enter a valid budget');
      return;
    }

    if (budget != null && budget < 0) {
      _showMessage('Budget cannot be negative');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final newBudget = budget ?? 0;

      await _firestore.collection('users').doc(user.uid).set(
        {
          'phone': user.phoneNumber ?? '',
          'monthlyBudget': newBudget,
          'preferences': {
            'mode': _mode,
            'comfort': _comfortMode,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _monthlyBudget = newBudget;

      if (mounted) {
        _showMessage('Profile saved successfully ✓');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to save profile');
      }
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  // ============================================================
  // OPEN ADD RIDE SCREEN
  // ============================================================

  Future<void> _openAddRideScreen() async {
    final result = await Navigator.of(context).push<
        Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const AddRideScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final provider =
        result['provider']?.toString() ?? 'Other';

    final category =
        result['category']?.toString() ?? 'Ride';

    final amountValue = result['amount'];

    final double? amount = amountValue is num
        ? amountValue.toDouble()
        : double.tryParse(
            amountValue?.toString() ?? '',
          );

    if (amount == null || amount <= 0) {
      _showMessage('Invalid ride amount');
      return;
    }

    await _addRideSpending(
      provider: provider,
      category: category,
      amount: amount,
    );
  }

  // ============================================================
  // ADD RIDE SPENDING TO FIRESTORE
  // ============================================================

  Future<void> _addRideSpending({
    required String provider,
    required String category,
    required double amount,
  }) async {
    final user = _user;

    if (user == null) {
      _showMessage('Please login first');
      return;
    }

    if (amount <= 0) {
      _showMessage('Invalid ride amount');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .add({
        'amount': amount,
        'provider': provider,
        'category': category,
        'type': 'ride',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadMonthlySpending();

      if (mounted) {
        _showMessage('Ride spending added ✓');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to add ride spending');
      }
    }
  }

  // ============================================================
  // DELETE SPENDING
  // ============================================================

  Future<void> _deleteSpending(
    String documentId,
  ) async {
    final user = _user;

    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(documentId)
          .delete();

      await _loadMonthlySpending();

      if (mounted) {
        _showMessage('Spending entry removed');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to remove entry');
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _loadMonthlySpending();
              },
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user),

                    const SizedBox(height: 24),

                    _buildSectionTitle('This Month'),

                    const SizedBox(height: 12),

                    _buildBudgetDashboard(),

                    const SizedBox(height: 24),

                    _buildAddSpendingButton(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Ride Spending'),

                    const SizedBox(height: 12),

                    _buildSpendingHistory(),

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      'Travel Preferences',
                    ),

                    const SizedBox(height: 12),

                    _buildPreferenceCard(),

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      'Monthly Transport Budget',
                    ),

                    const SizedBox(height: 12),

                    _buildBudgetCard(),

                    const SizedBox(height: 28),

                    _buildSaveButton(),

                    const SizedBox(height: 16),

                    _buildLogoutButton(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    User? user,
  ) {
    final phone =
        user?.phoneNumber ?? 'Phone not available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(
              alpha: 0.18,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'KaroCab User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.85,
                    ),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  // ============================================================
  // BUDGET DASHBOARD
  // ============================================================

  Widget _buildBudgetDashboard() {
    final double remaining =
        _monthlyBudget - _monthlySpent;

    final double safeRemaining =
        remaining < 0 ? 0 : remaining;

    final now = DateTime.now();

    final int daysInMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ).day;

    final int remainingDays =
        daysInMonth - now.day + 1;

    final double averagePerDay =
        remainingDays > 0
            ? safeRemaining / remainingDays
            : 0;

    double progress = 0;

    if (_monthlyBudget > 0) {
      progress =
          _monthlySpent / _monthlyBudget;

      if (progress > 1) {
        progress = 1;
      }
    }

    final bool overBudget =
        _monthlyBudget > 0 &&
        _monthlySpent > _monthlyBudget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transport Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Current month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_monthlyBudget > 0)
            Column(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor:
                        const Color(0xFFE5E7EB),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      overBudget
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          Row(
            children: [
              Expanded(
                child: _buildMoneyStat(
                  title: 'Budget',
                  amount: _monthlyBudget,
                  icon:
                      Icons.account_balance_wallet_outlined,
                ),
              ),
              Expanded(
                child: _buildMoneyStat(
                  title: 'Spent',
                  amount: _monthlySpent,
                  icon: Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildMoneyStat(
                  title: 'Remaining',
                  amount: safeRemaining,
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: overBudget
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  overBudget
                      ? Icons.warning_amber_rounded
                      : Icons.calendar_today_outlined,
                  color: overBudget
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    overBudget
                        ? 'You are ₹${(_monthlySpent - _monthlyBudget).toStringAsFixed(0)} over your monthly budget.'
                        : _monthlyBudget <= 0
                            ? 'Set a monthly budget to start tracking your daily limit.'
                            : 'You can spend about ₹${averagePerDay.toStringAsFixed(0)} per remaining day.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: overBudget
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONEY STAT
  // ============================================================

  Widget _buildMoneyStat({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(height: 5),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD RIDE BUTTON
  // ============================================================

  Widget _buildAddSpendingButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _openAddRideScreen,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Record Completed Ride',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SPENDING HISTORY
  // ============================================================

  Widget _buildSpendingHistory() {
    if (_loadingSpending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_spendingHistory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 38,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 10),
            Text(
              'No rides recorded this month',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add completed rides to track your transport spending.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: List.generate(
          _spendingHistory.length,
          (index) {
            final expense =
                _spendingHistory[index];

            final provider =
                expense['provider']?.toString() ??
                    'Unknown';

            final category =
                expense['category']?.toString() ??
                    'Ride';

            final amountValue =
                expense['amount'];

            final double amount =
                amountValue is num
                    ? amountValue.toDouble()
                    : double.tryParse(
                          amountValue?.toString() ?? '',
                        ) ??
                        0;

            final createdAt =
                expense['createdAt'];

            String dateText = 'This month';

            if (createdAt is Timestamp) {
              final date = createdAt.toDate();

              dateText =
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year}';
            }

            final id =
                expense['id']?.toString();

            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category
                              .toLowerCase()
                              .contains('auto')
                          ? Icons.electric_rickshaw_rounded
                          : Icons.local_taxi_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    '$provider $category',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (id != null)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteSpending(id);
                            }
                          },
                          itemBuilder:
                              (context) =>
                                  const [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (index <
                    _spendingHistory.length - 1)
                  const Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 14,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PREFERENCE CARD
  // ============================================================

  Widget _buildPreferenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How do you usually choose a ride?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildModeOption(
            value: 'budget',
            title: 'Budget',
            subtitle: 'Prefer lower fares',
            icon: Icons.savings_outlined,
          ),

          _buildModeOption(
            value: 'speed',
            title: 'Fast',
            subtitle:
                'Prefer shorter waiting time',
            icon: Icons.bolt_outlined,
          ),

          _buildModeOption(
            value: 'balanced',
            title: 'Balanced',
            subtitle:
                'Balance price and speed',
            icon: Icons.balance_outlined,
          ),

          const Divider(height: 24),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _comfortMode,
            onChanged: (value) {
              setState(() {
                _comfortMode = value;
              });
            },
            title: const Text(
              'Comfort priority',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Give more importance to comfortable rides',
            ),
            secondary: const Icon(
              Icons.airline_seat_recline_extra_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE OPTION
  // ============================================================

  Widget _buildModeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _mode == value;

    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _mode = value;
        });
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEFF6FF)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUDGET CARD
  // ============================================================

  Widget _buildBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your monthly cab/transport budget',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _budgetController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.currency_rupee,
                color: Color(0xFF2563EB),
              ),
              hintText: 'Example: 5000',
              labelText: 'Monthly Budget',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed:
            _saving ? null : _saveProfile,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.save_outlined,
              ),
        label: Text(
          _saving
              ? 'Saving...'
              : 'Save Preferences',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF93C5FD),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFFDC2626),
          side: const BorderSide(
            color: Color(0xFFFCA5A5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADD RIDE SCREEN
// ============================================================================

class AddRideScreen extends StatefulWidget {
  const AddRideScreen({super.key});

  @override
  State<AddRideScreen> createState() =>
      _AddRideScreenState();
}

class _AddRideScreenState
    extends State<AddRideScreen> {
  final TextEditingController _providerController =
      TextEditingController(text: 'Uber');

  final TextEditingController _categoryController =
      TextEditingController(text: 'Cab');

  final TextEditingController _amountController =
      TextEditingController();

  @override
  void dispose() {
    _providerController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submitRide() {
    final provider =
        _providerController.text.trim();

    final category =
        _categoryController.text.trim();

    final amount =
        double.tryParse(
      _amountController.text.trim(),
    );

    if (provider.isEmpty) {
      _showMessage('Enter provider name');
      return;
    }

    if (category.isEmpty) {
      _showMessage('Enter ride type');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount');
      return;
    }

    Navigator.of(context).pop(
      {
        'provider': provider,
        'category': category,
        'amount': amount,
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Record Completed Ride',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFFE5E7EB,
                    ),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons
                          .receipt_long_rounded,
                      color:
                          Color(0xFF2563EB),
                      size: 38,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      'Add your completed ride',
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF111827),
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Text(
                      'This amount will be included in your current monthly transport spending.',
                      style:
                          TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // PROVIDER
              // ==================================================

              const Text(
                'Provider',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF374151),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _providerController,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    InputDecoration(
                  hintText:
                      'Uber / Ola / Other',
                  prefixIcon:
                      const Icon(
                    Icons
                        .local_taxi_outlined,
                    color:
                        Color(0xFF2563EB),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // CATEGORY
              // ==================================================

              const Text(
                'Ride Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF374151),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _categoryController,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    InputDecoration(
                  hintText:
                      'Cab / Auto / Bike',
                  prefixIcon:
                      const Icon(
                    Icons
                        .directions_car_outlined,
                    color:
                        Color(0xFF2563EB),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // AMOUNT
              // ==================================================

              const Text(
                'Amount Paid',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF374151),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _amountController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      'Example: 250',
                  prefixIcon:
                      const Icon(
                    Icons
                        .currency_rupee,
                    color:
                        Color(0xFF2563EB),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // ADD BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _submitRide,
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: const Text(
                    'Add Ride',
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Center(
                child: Text(
                  'This will update your monthly transport spending.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 🎨 โทนสีหลัก
const Color primaryBlue = Color(0xFF1E56A0);
const Color darkBlueAppBar = Color(0xFF16315C);
const Color bgGrey = Color(0xFFF4F7F6);

// 📌 เอา URL ใหม่ที่ Deploy มาแปะตรงนี้นะครับ!
const String gasUrl =
    "https://script.google.com/macros/s/AKfycbxsfh0OFDZTKU9hy1QPN2XKyJGk_ckIEqPb45Uob9owrLtrR7jP3gaDAo_1RqHzER-dMA/exec";

void main() {
  runApp(
    MaterialApp(
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBlueAppBar,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 3,
        ),
      ),
    ),
  );
}

class Supervisor {
  String name, password, warehouse, area, shift;
  Supervisor({
    required this.name,
    required this.password,
    required this.warehouse,
    required this.area,
    required this.shift,
  });
  factory Supervisor.fromJson(Map<String, dynamic> json) => Supervisor(
    name: json['name'].toString().trim(),
    password: json['password'].toString().trim(),
    warehouse: json['warehouse'].toString().trim(),
    area: json['area'].toString().trim(),
    shift: json['shift'].toString().trim(),
  );
}

class Employee {
  String name, area, shift, warehouse, status;
  bool isSelected;
  int? startH, startM;
  Employee({
    required this.name,
    required this.area,
    required this.shift,
    required this.warehouse,
    this.status = 'มาปกติ',
    this.isSelected = false,
    this.startH,
    this.startM,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'area': area,
    'shift': shift,
    'warehouse': warehouse,
    'status': status,
    'isSelected': isSelected,
    'startH': startH,
    'startM': startM,
  };
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    name: json['name'],
    area: json['area'],
    shift: json['shift'],
    warehouse: json['warehouse'],
    status: json['status'],
    isSelected: json['isSelected'],
    startH: json['startH'],
    startM: json['startM'],
  );
}

String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<Supervisor> supervisors = [];
  Supervisor? selectedUser;
  final TextEditingController _passController = TextEditingController();
  bool isLoading = true, _obscure = true;

  @override
  void initState() {
    super.initState();
    _fetchAuth();
  }

  Future<void> _fetchAuth() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse("$gasUrl?t=${DateTime.now().millisecondsSinceEpoch}"),
      );
      if (res.statusCode == 200 || res.statusCode == 302) {
        var data = jsonDecode(res.body);
        if (data != null && data['supervisor_db'] != null)
          setState(() {
            supervisors = (data['supervisor_db'] as List)
                .map((s) => Supervisor.fromJson(s))
                .toList();
            isLoading = false;
          });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _login() {
    if (selectedUser == null ||
        _passController.text != selectedUser!.password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ข้อมูลไม่ถูกต้อง"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => OTDashboard(user: selectedUser!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(
                Icons.access_time_filled,
                size: 80,
                color: primaryBlue,
              ),
              const SizedBox(height: 15),
              const Text(
                'OT Management',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryBlue, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Supervisor>(
                    isExpanded: true,
                    hint: const Text("เลือกชื่อหัวหน้างาน"),
                    value: selectedUser,
                    items: supervisors
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedUser = v),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock, color: primaryBlue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _login,
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

class OTDashboard extends StatefulWidget {
  final Supervisor user;
  const OTDashboard({Key? key, required this.user}) : super(key: key);
  @override
  State<OTDashboard> createState() => _OTDashboardState();
}

class _OTDashboardState extends State<OTDashboard> {
  String? selWh, selArea, selShift, selectedFilterTime;
  Map<String, dynamic> empDb = {};
  List<Employee> currentList = [];
  bool isLoading = true, isSending = false, showOt = false;
  TimeOfDay? tIn, tOt;
  List<String> pendingAlerts = []; // เก็บ Format: warehouse_area_shift

  // 🛠️ ตัวแปรควบคุมช่องค้นหาและช่องเหตุผล
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _checkPendingTasks();
  }

  Future<void> _checkPendingTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> alerts = [];
    for (String key in prefs.getKeys()) {
      if (key.startsWith("save_")) {
        try {
          var emps =
              jsonDecode(prefs.getString(key) ?? "{}")['employees'] as List;
          if (emps.any((e) => e['startH'] != null)) {
            alerts.add(key.substring(5)); // เก็บค่าแบบ WH_AREA_SHIFT
          } else {
            await prefs.remove(key);
          }
        } catch (e) {
          await prefs.remove(key);
        }
      }
    }
    setState(() => pendingAlerts = alerts);
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse("$gasUrl?t=${DateTime.now().millisecondsSinceEpoch}"),
      );
      if (res.statusCode == 200 || res.statusCode == 302) {
        setState(() {
          empDb = jsonDecode(res.body)['employee_db'];
          isLoading = false;
        });
        if (selWh != null && selArea != null && selShift != null)
          _loadEmployees();
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    List<Employee> filtered = [];
    if (empDb[selWh] != null) {
      filtered = (empDb[selWh] as List)
          .where(
            (e) =>
                _norm(selArea!).contains(_norm(e['area'].toString())) &&
                _norm(selShift!).contains(_norm(e['shift'].toString())),
          )
          .map(
            (i) => Employee(
              name: i['name'].toString().trim(),
              area: i['area'].toString().trim(),
              shift: i['shift'].toString().trim(),
              warehouse: selWh!,
            ),
          )
          .toList();
    }
    setState(() {
      currentList = filtered;
      showOt = false;
      _searchController.clear();
      _reasonController.clear();
    });

    String? saved = prefs.getString("save_${selWh}_${selArea}_$selShift");
    if (saved != null) {
      setState(() {
        currentList = (jsonDecode(saved)['employees'] as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      });
      if (currentList.isNotEmpty && !currentList.any((e) => e.startH == null))
        showOt = true;
    }
  }

  // 🛠️ เช็คว่าเมนูที่กำลังโชว์อยู่ (คลัง/จุดงาน/กะ) มีงานค้างอยู่ข้างในไหม จะได้ทำกรอบสีส้ม
  bool _hasPendingInside(String item, String level) {
    if (level == "WH")
      return pendingAlerts.any((a) => a.startsWith("${item}_"));
    if (level == "AREA")
      return pendingAlerts.any((a) => a.startsWith("${selWh}_${item}_"));
    if (level == "SHIFT")
      return pendingAlerts.any((a) => a == "${selWh}_${selArea}_$item");
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    String hT = (selWh == null)
        ? "ยินดีต้อนรับ, ${widget.user.name}"
        : (selArea == null)
        ? selWh!
        : (selShift == null)
        ? selArea!
        : "$selArea - กะ $selShift";
    return Scaffold(
      appBar: AppBar(
        leading: (selWh != null)
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const LoginScreen()),
                ),
              ),
        title: Text(
          hT,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _buildView(),
    );
  }

  void _goBack() => setState(() {
    if (selShift != null)
      selShift = null;
    else if (selArea != null)
      selArea = null;
    else
      selWh = null;
  });

  // 🛠️ ป้ายแจ้งเตือนที่กด Link นำทางได้เลย
  Widget _buildPendingBanner() {
    if (pendingAlerts.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16).copyWith(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "มีงานค้าง (กดเพื่อไปยังจุดงาน):",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () async {
                  final p = await SharedPreferences.getInstance();
                  for (String k in p.getKeys())
                    if (k.startsWith("save_")) await p.remove(k);
                  setState(() => pendingAlerts.clear());
                },
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...pendingAlerts.map((a) {
            List<String> p = a.split('_');
            if (p.length < 3) return const SizedBox.shrink();
            String w = p[0];
            String ar = p[1];
            String s = p.sublist(2).join('_');
            return InkWell(
              onTap: () {
                // เลื่อนไปหน้านั้นทันที
                setState(() {
                  selWh = w;
                  selArea = ar;
                  selShift = s;
                  _loadEmployees();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "➔ $w > $ar (กะ $s)",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildView() {
    if (selWh != null && selArea != null && selShift != null)
      return _buildMain();
    Widget gridContent;
    if (selWh == null) {
      var whs = empDb.keys.toList();
      if (widget.user.warehouse != "ALL")
        whs = whs
            .where((w) => _norm(widget.user.warehouse).contains(_norm(w)))
            .toList();
      gridContent = _buildGrid(
        whs,
        (v) => setState(() => selWh = v),
        Icons.warehouse,
        "WH",
      );
    } else if (selArea == null) {
      var areas = (empDb[selWh] as List)
          .map((e) => e['area'].toString().trim())
          .toSet()
          .toList();
      if (widget.user.area != "ALL")
        areas = areas
            .where((a) => _norm(widget.user.area).contains(_norm(a)))
            .toList();
      gridContent = Column(
        children: [
          _backBtn(),
          Expanded(
            child: _buildGrid(
              areas,
              (v) => setState(() => selArea = v),
              Icons.groups,
              "AREA",
            ),
          ),
        ],
      );
    } else {
      var shifts = (empDb[selWh] as List)
          .where((e) => _norm(selArea!).contains(_norm(e['area'].toString())))
          .map((e) => e['shift'].toString().trim())
          .toSet()
          .toList();
      if (widget.user.shift != "ALL")
        shifts = shifts
            .where((s) => _norm(widget.user.shift).contains(_norm(s)))
            .toList();
      gridContent = Column(
        children: [
          _backBtn(),
          Expanded(
            child: _buildGrid(
              shifts,
              (v) {
                setState(() => selShift = v);
                _loadEmployees();
              },
              Icons.access_time,
              "SHIFT",
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildPendingBanner(),
        Expanded(child: gridContent),
      ],
    );
  }

  Widget _backBtn() => Padding(
    padding: const EdgeInsets.all(16),
    child: OutlinedButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back),
      label: const Text(
        "ย้อนกลับ / แก้ไข",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: primaryBlue, width: 2),
      ),
    ),
  );

  // 🛠️ การ์ดเมนู พร้อมระบบกรอบสีส้มแจ้งงานค้าง
  Widget _buildGrid(
    List<String> items,
    Function(String) onSel,
    IconData icon,
    String level,
  ) {
    return LayoutBuilder(
      builder: (c, constraints) {
        double w = items.length == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 15) / 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: items.map((item) {
                bool hasPending = _hasPendingInside(
                  item,
                  level,
                ); // เช็คว่าในปุ่มนี้มีงานค้างไหม
                return SizedBox(
                  width: w,
                  child: InkWell(
                    onTap: () => onSel(item),
                    child: Card(
                      color: hasPending ? Colors.orange.shade50 : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: hasPending ? Colors.orange : primaryBlue,
                          width: hasPending ? 2.5 : 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              size: 40,
                              color: hasPending
                                  ? Colors.orange.shade800
                                  : primaryBlue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: hasPending
                                    ? Colors.orange.shade900
                                    : darkBlueAppBar,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMain() {
    // 🛠️ ระบบค้นหาชื่อพนักงาน
    var filteredList = currentList
        .where(
          (e) => e.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();

    final p = filteredList.where((e) => e.startH == null).toList();
    final d = filteredList.where((e) => e.startH != null).toList();
    final times =
        currentList
            .where((e) => e.startH != null)
            .map(
              (e) =>
                  "${e.startH.toString().padLeft(2, '0')}:${e.startM.toString().padLeft(2, '0')}",
            )
            .toSet()
            .toList()
          ..sort();
    String? earliest = times.isNotEmpty ? times.first : null;

    return Column(
      children: [
        _backBtn(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "ค้นหาชื่อพนักงาน...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _timePanel(),
                if (p.isNotEmpty) ...[
                  _headerWithBulk("รอเข้างาน (${p.length})", Colors.orange, p),
                  ...p.map((e) => _empCard(e)).toList(),
                ],
                if (d.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  _otToggle(d.length),
                  if (showOt) ...[
                    _filterBar(times, earliest, d),
                    _headerWithBulk(
                      "ดำเนินการ OT",
                      Colors.green,
                      d
                          .where(
                            (e) =>
                                selectedFilterTime == null ||
                                "${e.startH.toString().padLeft(2, '0')}:${e.startM.toString().padLeft(2, '0')}" ==
                                    selectedFilterTime,
                          )
                          .toList(),
                    ),
                    ...d
                        .where(
                          (e) =>
                              selectedFilterTime == null ||
                              "${e.startH.toString().padLeft(2, '0')}:${e.startM.toString().padLeft(2, '0')}" ==
                                  selectedFilterTime,
                        )
                        .map(
                          (e) => _empCard(e, isDone: true, earliest: earliest),
                        )
                        .toList(),
                  ],
                ],
                const SizedBox(height: 30),
                _submitBtn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePanel() => Container(
    padding: const EdgeInsets.all(15),
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ระบุเวลาทำงาน",
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            if (tIn != null || tOt != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  tIn = null;
                  tOt = null;
                  _reasonController.clear();
                }),
                icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                label: const Text(
                  "ล้างเวลา",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pickTime(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text("เข้า: ${_fmt(tIn)}"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pickTime(false),
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue, width: 2),
                  backgroundColor: Colors.white,
                  foregroundColor: primaryBlue,
                ),
                child: Text("จบ OT: ${_fmt(tOt)}"),
              ),
            ),
          ],
        ),
        // 🛠️ ช่องระบุเหตุผล OT (โชว์เฉพาะตอนเลือกเวลาจบ OT แล้ว)
        if (tOt != null)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "ระบุเหตุผลการทำ OT (จำเป็น)",
                prefixIcon: const Icon(Icons.edit_note, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ),
      ],
    ),
  );

  Widget _headerWithBulk(String t, Color c, List<Employee> l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 12, color: c),
            const SizedBox(width: 8),
            Text(
              t,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  for (var x in l) x.isSelected = true;
                }),
                icon: const Icon(Icons.checklist, size: 18),
                label: const Text("เลือกทั้งหมด"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  for (var x in l) x.isSelected = false;
                }),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("ล้างการเลือก"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _filterBar(List<String> t, String? e, List<Employee> l) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ChoiceChip(
            label: const Text("ทั้งหมด"),
            selected: selectedFilterTime == null,
            onSelected: (v) => setState(() {
              selectedFilterTime = null;
              for (var x in l) x.isSelected = false;
            }),
          ),
          ...t
              .map(
                (time) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text("ชุด $time"),
                    selected: selectedFilterTime == time,
                    onSelected: (v) {
                      if (time != e) return;
                      setState(() {
                        selectedFilterTime = v ? time : null;
                        for (var x in l)
                          x.isSelected =
                              (v &&
                              "${x.startH.toString().padLeft(2, '0')}:${x.startM.toString().padLeft(2, '0')}" ==
                                  time);
                      });
                    },
                  ),
                ),
              )
              .toList(),
        ],
      ),
    ),
  );

  Widget _empCard(Employee e, {bool isDone = false, String? earliest}) {
    String t =
        "${e.startH?.toString().padLeft(2, '0') ?? '--'}:${e.startM?.toString().padLeft(2, '0') ?? '--'}";
    bool locked = isDone && earliest != null && t != earliest;
    String sub = e.status;
    if (isDone) {
      sub += " (เข้า: $t)";
      if (tOt != null && !locked) {
        double otV = _calcPr(e.startH!, e.startM!, tOt!);
        sub += " | จบ: ${_fmt(tOt)} (${otV.toStringAsFixed(1)} ชม.)";
      }
    }
    return Card(
      color: locked
          ? Colors.grey.shade200
          : (isDone ? Colors.green.shade50 : Colors.white),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        title: Text(
          e.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: locked ? Colors.grey : darkBlueAppBar,
          ),
        ),
        subtitle: Text(
          sub,
          style: TextStyle(
            color: (isDone && tOt != null && !locked)
                ? Colors.red.shade700
                : (locked ? Colors.grey : Colors.blueGrey),
            fontWeight: (isDone && tOt != null && !locked)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        trailing: locked
            ? const Icon(Icons.lock, color: Colors.grey)
            : Checkbox(
                value: e.isSelected,
                activeColor: primaryBlue,
                onChanged: (v) => setState(() => e.isSelected = v!),
              ),
      ),
    );
  }

  Widget _otToggle(int n) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: InkWell(
      onTap: () => setState(() => showOt = !showOt),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: showOt ? Colors.blue.shade50 : primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showOt ? Icons.visibility_off : Icons.monetization_on,
              color: primaryBlue,
            ),
            const SizedBox(width: 10),
            Text(
              showOt ? "ซ่อนหน้าต่าง OT" : "เริ่มหยอด OT ($n คน)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _submitDialog() {
    bool isOT = tOt != null;
    var list = currentList
        .where((e) => e.isSelected && e.status == 'มาปกติ')
        .toList();
    if (list.isEmpty) return;
    if (isOT && list.any((e) => e.startH == null) && tIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ กรุณาระบุเวลา 'เข้า' ก่อนส่งยอด OT รวดเดียวครับ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🛡️ บังคับให้กรอกเหตุผล OT
    if (isOT && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ กรุณาระบุเหตุผลการทำ OT ด้วยครับ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: darkBlueAppBar,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOT ? Icons.assignment_turned_in : Icons.save,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOT ? 'ยืนยันยอด OT' : 'ยืนยันเวลาเข้า',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(15),
                itemCount: list.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, i) {
                  var e = list[i];
                  int? h = e.startH ?? tIn?.hour;
                  int? m = e.startM ?? tIn?.minute;
                  double otV = (h != null && m != null && tOt != null)
                      ? _calcPr(h, m, tOt!)
                      : 0.0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'เข้า: ${_fmtT(h, m)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (isOT)
                            Text(
                              '${otV.toStringAsFixed(1)} ชม.',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'แก้ไข',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOT ? Colors.green : primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(c);
                        _doSubmit(list);
                      },
                      child: const Text(
                        'ยืนยัน',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitBtn() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton.icon(
      onPressed: isSending ? null : _submitDialog,
      icon: const Icon(Icons.save),
      label: const Text(
        "บันทึกและส่งข้อมูล",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    ),
  );

  Future<void> _doSubmit(List<Employee> list) async {
    setState(() => isSending = true);
    try {
      if (tIn != null) {
        for (var e in list) {
          if (e.startH == null) {
            e.startH = tIn!.hour;
            e.startM = tIn!.minute;
          }
        }
      }

      if (tOt == null) {
        // กรณีลงเวลาเข้าอย่างเดียว (เก็บไว้ในเครื่อง)
        for (var e in list) e.isSelected = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("บันทึกเวลาเข้าสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // กรณีส่ง OT เข้า Google Sheet
        var payload = {
          "warehouse": selWh,
          "area": selArea,
          "shift": selShift,
          "reason": _reasonController.text.trim().isEmpty
              ? "-"
              : _reasonController.text.trim(),
          "employees": list.map((e) {
            // คำนวณเวลาเลิกปกติ (+9 ชม.)
            int nH = (e.startH! + 9) % 24;
            String sTime =
                "${e.startH!.toString().padLeft(2, '0')}:${e.startM!.toString().padLeft(2, '0')}";
            String nTime =
                "${nH.toString().padLeft(2, '0')}:${e.startM!.toString().padLeft(2, '0')}";
            String oTime =
                "${tOt!.hour.toString().padLeft(2, '0')}:${tOt!.minute.toString().padLeft(2, '0')}";
            double otHrs = _calcPr(e.startH!, e.startM!, tOt!);

            return {
              "name": e.name,
              "startTime": sTime,
              "normalEnd": nTime,
              "otEnd": oTime,
              "otHours": otHrs.toStringAsFixed(1),
            };
          }).toList(),
        };

        await http.post(Uri.parse(gasUrl), body: jsonEncode(payload));

        setState(() {
          currentList.removeWhere((e) => list.contains(e));
          tIn = null;
          tOt = null;
          _reasonController.clear();
          selectedFilterTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ส่ง OT สำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // จัดการ SharedPreferences
      final p = await SharedPreferences.getInstance();
      if (currentList.isEmpty) {
        await p.remove("save_${selWh}_${selArea}_$selShift");
        setState(() {
          selWh = null;
          selArea = null;
          selShift = null;
        });
      } else {
        await p.setString(
          "save_${selWh}_${selArea}_$selShift",
          jsonEncode({
            'employees': currentList.map((e) => e.toJson()).toList(),
          }),
        );
      }
      _checkPendingTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ผิดพลาด: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  double _calcPr(int h, int m, TimeOfDay t) {
    int s = h * 60 + m + 540, o = t.hour * 60 + t.minute;
    if (o < (s % 1440) && t.hour < 12) o += 1440;
    return (o - (s % 1440)) / 60.0;
  }

  Future<void> _pickTime(bool s) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (c, ch) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: ch!,
      ),
    );
    if (t != null) setState(() => s ? tIn = t : tOt = t);
  }

  String _fmt(TimeOfDay? t) => t == null
      ? "--:--"
      : "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  String _fmtT(int? h, int? m) => (h == null)
      ? "--:--"
      : "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
}

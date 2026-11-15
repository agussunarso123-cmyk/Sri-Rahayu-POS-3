import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const SriRahayuApp());
}

class SriRahayuApp extends StatelessWidget {
  const SriRahayuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sri Rahayu POS', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF137C5A)),
      scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F7F6)),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    home: const LoginGate(),
  );
}


class LoginGate extends StatefulWidget {
  const LoginGate({super.key});
  @override State<LoginGate> createState() => _LoginGateState();
}
class _LoginGateState extends State<LoginGate> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool busy = true, obscure = true;
  String error = '';
  String digest(String value) => sha256.convert(utf8.encode(value)).toString();

  @override void initState() {
    super.initState();
    _prepare();
  }
  Future<void> _prepare() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('login_user') == null) {
      await prefs.setString('login_user', 'admin');
      await prefs.setString('login_hash', digest('123456'));
    }
    if (mounted) setState(() => busy = false);
  }
  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('login_user') ?? 'admin';
    final savedHash = prefs.getString('login_hash') ?? digest('123456');
    if (username.text.trim() == savedUser && digest(password.text) == savedHash) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PosHome()));
    } else {
      setState(() => error = 'Nama akun atau kata sandi salah.');
    }
  }
  @override Widget build(BuildContext context) {
    if (busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CircleAvatar(radius: 34, backgroundColor: Color(0xFFE7F2EC), child: Icon(Icons.storefront, size: 36, color: Color(0xFF137C5A))),
            const SizedBox(height: 16),
            const Text('Sri Rahayu POS', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Silakan masuk ke akun Anda', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            TextField(controller: username, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nama akun', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: 'Kata sandi', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
            if (error.isNotEmpty) ...[const SizedBox(height: 10), Text(error, style: const TextStyle(color: Colors.red))],
            const SizedBox(height: 18),
            FilledButton(onPressed: _login, child: const Padding(padding: EdgeInsets.all(12), child: Text('Masuk'))),
            const SizedBox(height: 12),
            const Text('Login awal: admin  •  kata sandi: 123456', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54))
          ],
        ))),
      ))),
    );
  }
}

class Product {
  Product(this.id, this.name, this.category, this.price, this.stock, [this.image = '']);
  String id, name, category, image;
  int price, stock;
  Map<String,dynamic> toJson() => {'id':id,'name':name,'category':category,'price':price,'stock':stock,'image':image};
  factory Product.fromJson(Map<String,dynamic> j) => Product(j['id']??'',j['name']??'',j['category']??'Makanan',(j['price'] as num?)?.toInt()??0,(j['stock'] as num?)?.toInt()??0,j['image']??'');
}
class Sale {
  Sale(this.date,this.total,this.branch,this.items,{this.payment='Tunai',this.cashReceived=0});
  DateTime date; int total; String branch; List<Map<String,dynamic>> items;
  String payment; int cashReceived;
  int get changeDue => cashReceived > total ? cashReceived-total : 0;
  Map<String,dynamic> toJson()=>{'date':date.toIso8601String(),'total':total,'branch':branch,'items':items,'payment':payment,'cashReceived':cashReceived};
  factory Sale.fromJson(Map<String,dynamic> j)=>Sale(DateTime.tryParse(j['date']??'')??DateTime.now(),(j['total'] as num?)?.toInt()??0,j['branch']??'Cabang Utama',List<Map<String,dynamic>>.from((j['items']??[]).map((e)=>Map<String,dynamic>.from(e))),payment:j['payment']??'Tunai',cashReceived:(j['cashReceived'] as num?)?.toInt()??0);
}

class Expense {
  Expense(this.date,this.amount,this.branch,this.category,this.note);
  DateTime date; int amount; String branch,category,note;
  Map<String,dynamic> toJson()=>{'date':date.toIso8601String(),'amount':amount,'branch':branch,'category':category,'note':note};
  factory Expense.fromJson(Map<String,dynamic> j)=>Expense(DateTime.tryParse(j['date']??'')??DateTime.now(),(j['amount'] as num?)?.toInt()??0,j['branch']??'Cabang Utama',j['category']??'Lainnya',j['note']??'');
}

class Employee {
  Employee(this.id,this.name,this.salary);
  String id,name; int salary;
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'salary':salary};
  factory Employee.fromJson(Map<String,dynamic> j)=>Employee(j['id']??'',j['name']??'',(j['salary'] as num?)?.toInt()??0);
}
class StaffEntry {
  StaffEntry(this.date,this.employeeId,this.employeeName,this.branch,this.type,this.amount,this.note);
  DateTime date; String employeeId,employeeName,branch,type,note; int amount;
  Map<String,dynamic> toJson()=>{'date':date.toIso8601String(),'employeeId':employeeId,'employeeName':employeeName,'branch':branch,'type':type,'amount':amount,'note':note};
  factory StaffEntry.fromJson(Map<String,dynamic> j)=>StaffEntry(DateTime.tryParse(j['date']??'')??DateTime.now(),j['employeeId']??'',j['employeeName']??'',j['branch']??'Cabang Utama',j['type']??'Gaji', (j['amount'] as num?)?.toInt()??0,j['note']??'');
}


class LeaveEntry {
  LeaveEntry(this.date,this.employeeId,this.employeeName,this.branch,this.type,this.note);
  DateTime date; String employeeId,employeeName,branch,type,note;
  Map<String,dynamic> toJson()=>{'date':date.toIso8601String(),'employeeId':employeeId,'employeeName':employeeName,'branch':branch,'type':type,'note':note};
  factory LeaveEntry.fromJson(Map<String,dynamic> j)=>LeaveEntry(DateTime.tryParse(j['date']??'')??DateTime.now(),j['employeeId']??'',j['employeeName']??'',j['branch']??'Cabang Utama',j['type']??'Libur',j['note']??'');
}

class PosHome extends StatefulWidget {
  const PosHome({super.key});
  @override State<PosHome> createState()=>_PosHomeState();
}
class _PosHomeState extends State<PosHome> {
  int tab=0; bool loading=true;
  String branch='Cabang Utama';
  List<String> branches=['Cabang Utama'];
  List<Product> products=[];
  List<Sale> sales=[];
  List<Expense> expenses=[];
  List<Employee> employees=[];
  List<StaffEntry> staffEntries=[];
  List<LeaveEntry> leaveEntries=[];
  final Map<String,int> cart={};
  final picker=ImagePicker();
  final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    try {
      products=(jsonDecode(p.getString('products')??'[]') as List).map((e)=>Product.fromJson(Map<String,dynamic>.from(e))).toList();
      sales=(jsonDecode(p.getString('sales')??'[]') as List).map((e)=>Sale.fromJson(Map<String,dynamic>.from(e))).toList();
      expenses=(jsonDecode(p.getString('expenses')??'[]') as List).map((e)=>Expense.fromJson(Map<String,dynamic>.from(e))).toList();
      employees=(jsonDecode(p.getString('employees')??'[]') as List).map((e)=>Employee.fromJson(Map<String,dynamic>.from(e))).toList();
      staffEntries=(jsonDecode(p.getString('staff_entries')??'[]') as List).map((e)=>StaffEntry.fromJson(Map<String,dynamic>.from(e))).toList();
      leaveEntries=(jsonDecode(p.getString('leave_entries')??'[]') as List).map((e)=>LeaveEntry.fromJson(Map<String,dynamic>.from(e))).toList();
      branches=List<String>.from(jsonDecode(p.getString('branches')??'["Cabang Utama"]'));
      branch=p.getString('branch')??branches.first;
    } catch (_) { products=[]; sales=[]; branches=['Cabang Utama']; branch=branches.first; }
    if(products.isEmpty) products=[Product('1','Bakso Original','Bakso',15000,50),Product('2','Mie Ayam','Makanan',13000,40),Product('3','Bakso Urat','Bakso',18000,35),Product('4','Es Teh','Minuman',5000,80)];
    await save();
    if(mounted)setState(()=>loading=false);
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('products',jsonEncode(products.map((e)=>e.toJson()).toList()));
    await p.setString('sales',jsonEncode(sales.map((e)=>e.toJson()).toList()));
    await p.setString('expenses',jsonEncode(expenses.map((e)=>e.toJson()).toList()));
    await p.setString('employees',jsonEncode(employees.map((e)=>e.toJson()).toList()));
    await p.setString('staff_entries',jsonEncode(staffEntries.map((e)=>e.toJson()).toList()));
    await p.setString('leave_entries',jsonEncode(leaveEntries.map((e)=>e.toJson()).toList()));
    await p.setString('branches',jsonEncode(branches)); await p.setString('branch',branch);
  }
  int get total=>cart.entries.fold(0,(a,e){final p=products.firstWhere((x)=>x.id==e.key);return a+p.price*e.value;});
  List<Sale> get branchSales=>sales.where((s)=>s.branch==branch).toList();
  int get todaySales {final n=DateTime.now();return branchSales.where((s)=>s.date.year==n.year&&s.date.month==n.month&&s.date.day==n.day).fold(0,(a,s)=>a+s.total);}
  int get todayCount {final n=DateTime.now();return branchSales.where((s)=>s.date.year==n.year&&s.date.month==n.month&&s.date.day==n.day).length;}


  Future<void> changeLoginPassword() async {
    final oldPass = TextEditingController(), newPass = TextEditingController(), confirm = TextEditingController();
    String message = '';
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
      title: const Text('Ubah kata sandi akun'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi lama')),
        TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi baru')),
        TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi kata sandi baru')),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message, style: const TextStyle(color: Colors.red)))
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final oldHash = sha256.convert(utf8.encode(oldPass.text)).toString();
          if (oldHash != (prefs.getString('login_hash') ?? '')) { refresh(() => message = 'Kata sandi lama tidak benar.'); return; }
          if (newPass.text.length < 6) { refresh(() => message = 'Kata sandi baru minimal 6 karakter.'); return; }
          if (newPass.text != confirm.text) { refresh(() => message = 'Konfirmasi kata sandi tidak sama.'); return; }
          await prefs.setString('login_hash', sha256.convert(utf8.encode(newPass.text)).toString());
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kata sandi berhasil diubah.')));
        }, child: const Text('Simpan'))
      ]
    )));
  }
  void logout() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginGate()), (route) => false);
  }

  Future<void> addProduct() async {
    final name=TextEditingController(), cat=TextEditingController(text:'Makanan'), price=TextEditingController(), stock=TextEditingController(text:'0');
    String image='';
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Tambah menu'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        InkWell(onTap:()async{final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:75,maxWidth:900);if(f!=null)refresh(()=>image=f.path);},
          child:Container(height:100,width:100,decoration:BoxDecoration(color:const Color(0xFFE7F2EC),borderRadius:BorderRadius.circular(14)),
            child:image.isEmpty?const Icon(Icons.add_a_photo,size:32):ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.file(File(image),fit:BoxFit.cover)))),
        const SizedBox(height:12),TextField(controller:name,decoration:const InputDecoration(labelText:'Nama menu')),
        const SizedBox(height:8),TextField(controller:cat,decoration:const InputDecoration(labelText:'Kategori')),
        const SizedBox(height:8),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Harga (Rp)')),
        const SizedBox(height:8),TextField(controller:stock,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Stok awal')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:(){
        final v=int.tryParse(price.text)??0;if(name.text.trim().isEmpty||v<=0)return;
        setState(()=>products.add(Product(DateTime.now().microsecondsSinceEpoch.toString(),name.text.trim(),cat.text.trim().isEmpty?'Makanan':cat.text.trim(),v,int.tryParse(stock.text)??0,image)));
        save();Navigator.pop(ctx);
      },child:const Text('Simpan'))],
    )));
  }
  Future<void> addExpense() async {
    final amount=TextEditingController(), note=TextEditingController();
    String category='Belanja bahan';
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Catat pengeluaran'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Jumlah (Rp)',prefixText:'Rp ')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Kategori'),items:const[
          DropdownMenuItem(value:'Belanja bahan',child:Text('Belanja bahan')),
          DropdownMenuItem(value:'Gaji',child:Text('Gaji')),
          DropdownMenuItem(value:'Sewa',child:Text('Sewa tempat')),
          DropdownMenuItem(value:'Listrik dan air',child:Text('Listrik dan air')),
          DropdownMenuItem(value:'Transportasi',child:Text('Transportasi')),
          DropdownMenuItem(value:'Lainnya',child:Text('Lainnya'))
        ],onChanged:(v)=>refresh(()=>category=v??'Lainnya')),
        const SizedBox(height:10),
        TextField(controller:note,decoration:const InputDecoration(labelText:'Catatan (opsional)'))
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
        FilledButton(onPressed:(){
          final value=int.tryParse(amount.text)??0;
          if(value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Masukkan jumlah pengeluaran yang benar')));return;}
          setState(()=>expenses.insert(0,Expense(DateTime.now(),value,branch,category,note.text.trim())));
          save();Navigator.pop(ctx);
        },child:const Text('Simpan'))
      ]
    )));
  }

  Future<void> changeStock(Product p) async {
    final c=TextEditingController(text:p.stock.toString());
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Stok '+p.name),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Jumlah stok')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:(){final v=int.tryParse(c.text);if(v==null||v<0)return;setState(()=>p.stock=v);save();Navigator.pop(ctx);},child:const Text('Simpan'))]));
  }
  int outstanding(Employee e) => staffEntries.where((x)=>x.employeeId==e.id && x.branch==branch).fold(0,(a,x)=>a+(x.type=='Kasbon'?x.amount:(x.type=='Potongan kasbon'?-x.amount:0)));
  int parseRupiah(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> addEmployee() async {
    final n=TextEditingController(),s=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Tambah karyawan'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'Nama karyawan')),
      TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Gaji pokok per bulan (Rp)')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:(){final v=parseRupiah(s.text);if(n.text.trim().isEmpty||v<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Masukkan gaji lebih dari Rp 0')));return;}setState(()=>employees.add(Employee(DateTime.now().microsecondsSinceEpoch.toString(),n.text.trim(),v)));save();Navigator.pop(ctx);},child:const Text('Simpan'))]));
  }
  Future<void> addStaffEntry(Employee e) async {
    String type = 'Gaji';
    final amount = TextEditingController(text: e.salary.toString());
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text('Catat • ${e.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis transaksi'),
                items: const [
                  DropdownMenuItem(value: 'Gaji', child: Text('Bayar gaji')),
                  DropdownMenuItem(value: 'Kasbon', child: Text('Berikan kasbon')),
                  DropdownMenuItem(value: 'Potongan kasbon', child: Text('Potong / cicil kasbon')),
                ],
                onChanged: (v) => refresh(() => type = v ?? 'Gaji'),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah (Rp)', prefixText: 'Rp '),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              if (type == 'Potongan kasbon')
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sisa kasbon: ${money.format(outstanding(e))}',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final v = parseRupiah(amount.text);
                if (v <= 0) return;
                if (type == 'Potongan kasbon' && v > outstanding(e)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Potongan melebihi sisa kasbon')),
                  );
                  return;
                }
                setState(() {
                  staffEntries.insert(
                    0,
                    StaffEntry(DateTime.now(), e.id, e.name, branch, type, v, note.text.trim()),
                  );
                });
                save();
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> addLeave(Employee e) async {
    DateTime selectedDate=DateTime.now();
    String type='Libur';
    final note=TextEditingController();
    await showDialog<void>(
      context:context,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
        title:Text('Catat libur • ${e.name}'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_month),title:const Text('Tanggal'),subtitle:Text(DateFormat('EEEE, dd MMMM yyyy','id_ID').format(selectedDate)),onTap:()async{
            final d=await showDatePicker(context:ctx,initialDate:selectedDate,firstDate:DateTime(2020),lastDate:DateTime(2100));
            if(d!=null)refresh(()=>selectedDate=d);
          }),
          DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Jenis ketidakhadiran'),items:const[
            DropdownMenuItem(value:'Libur',child:Text('Libur')),
            DropdownMenuItem(value:'Cuti',child:Text('Cuti')),
            DropdownMenuItem(value:'Izin',child:Text('Izin')),
            DropdownMenuItem(value:'Sakit',child:Text('Sakit')),
          ],onChanged:(v)=>refresh(()=>type=v??'Libur')),
          TextField(controller:note,maxLines:2,decoration:const InputDecoration(labelText:'Alasan / catatan (opsional)')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
          FilledButton(onPressed:(){
            setState(()=>leaveEntries.insert(0,LeaveEntry(selectedDate,e.id,e.name,branch,type,note.text.trim())));
            save();Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Jadwal libur berhasil disimpan')));
          },child:const Text('Simpan')),
        ],
      )),
    );
  }

  Future<void> printPayslip(Employee e) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan slip gaji',
    );
    if (selected == null || !mounted) return;
    final periodEntries = staffEntries.where((x) =>
      x.employeeId == e.id &&
      x.branch == branch &&
      x.date.year == selected.year &&
      x.date.month == selected.month
    ).toList();
    final grossRecorded = periodEntries.where((x) => x.type == 'Gaji').fold<int>(0, (a, x) => a + x.amount);
    final deduction = periodEntries.where((x) => x.type == 'Potongan kasbon').fold<int>(0, (a, x) => a + x.amount);
    final gross = grossRecorded > 0 ? grossRecorded : e.salary;
    final net = (gross - deduction).clamp(0, 1 << 31);
    final paidDate = periodEntries.where((x) => x.type == 'Gaji').isNotEmpty
      ? periodEntries.firstWhere((x) => x.type == 'Gaji').date
      : selected;
    final pdf = pw.Document();
    pw.Widget line(String label, String value, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('SRI RAHAYU POS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('SLIP GAJI KARYAWAN', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 14),
        pw.Divider(),
        line('Nama karyawan', e.name),
        line('Cabang', branch),
        line('Periode', DateFormat('MMMM yyyy', 'id_ID').format(selected)),
        line('Tanggal slip', DateFormat('dd MMMM yyyy', 'id_ID').format(paidDate)),
        pw.Divider(),
        line('Gaji pokok per bulan', money.format(e.salary)),
        line('Total gaji tercatat', money.format(grossRecorded)),
        line('Potongan kasbon', money.format(deduction)),
        pw.Divider(),
        line('GAJI BERSIH', money.format(net), bold: true),
        pw.Spacer(),
        pw.Text('Catatan: slip ini dibuat dari catatan gaji dan potongan kasbon pada aplikasi.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 24),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Column(children: [
            pw.Text('Penerima,'),
            pw.SizedBox(height: 42),
            pw.Text(e.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
      ]),
    ));
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Slip_Gaji_${e.name.replaceAll(' ', '_')}_${selected.year}_${selected.month}.pdf',
    );
  }

  Widget staffPage()=>Scaffold(backgroundColor:Colors.transparent,floatingActionButton:FloatingActionButton.extended(onPressed:addEmployee,icon:const Icon(Icons.person_add),label:const Text('Tambah karyawan')),body:ListView(padding:const EdgeInsets.all(14),children:[
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Rekap gaji & kasbon',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      Text('Total gaji dibayarkan: '+money.format(staffEntries.where((x)=>x.branch==branch&&x.type=='Gaji').fold(0,(a,x)=>a+x.amount))),
      Text('Sisa kasbon karyawan: '+money.format(employees.fold(0,(a,e)=>a+outstanding(e)))),
    ]))),
    const SizedBox(height:8),const Text('Daftar karyawan',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
    ...employees.map((e)=>Card(child:ExpansionTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(e.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Gaji pokok: '+money.format(e.salary)+' • Sisa kasbon: '+money.format(outstanding(e))),children:[
      Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Wrap(spacing:8,children:[
        FilledButton.tonal(onPressed:()=>addStaffEntry(e),child:const Text('Catat gaji / kasbon')),
        OutlinedButton.icon(onPressed:()=>printPayslip(e),icon:const Icon(Icons.print_outlined),label:const Text('Cetak slip gaji')),
        OutlinedButton.icon(onPressed:()=>addLeave(e),icon:const Icon(Icons.event_busy_outlined),label:const Text('Catat libur')),
      ])),
      ...leaveEntries.where((x)=>x.employeeId==e.id&&x.branch==branch).take(10).map((x)=>ListTile(dense:true,leading:const Icon(Icons.event_busy_outlined,color:Colors.deepOrange),title:Text(x.type+' • '+DateFormat('dd MMM yyyy','id_ID').format(x.date)),subtitle:Text(x.note.isEmpty?'Tidak ada catatan':x.note),trailing:IconButton(tooltip:'Hapus catatan',icon:const Icon(Icons.delete_outline),onPressed:(){
        setState(()=>leaveEntries.remove(x));save();
      }))),
      ...staffEntries.where((x)=>x.employeeId==e.id&&x.branch==branch).take(10).map((x)=>ListTile(dense:true,title:Text(x.type),subtitle:Text(DateFormat('dd MMM yyyy','id_ID').format(x.date)+(x.note.isEmpty?'':' • '+x.note)),trailing:Text(money.format(x.amount)))),
    ]))),
    if(employees.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Belum ada karyawan. Tambahkan karyawan untuk mulai mencatat gaji dan kasbon.'))),
  ]));

  Future<void> addBranch() async {
    final c=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Tambah cabang'),content:TextField(controller:c,decoration:const InputDecoration(labelText:'Nama cabang')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:(){final v=c.text.trim();if(v.isEmpty||branches.contains(v))return;setState((){branches.add(v);branch=v;cart.clear();});save();Navigator.pop(ctx);},child:const Text('Tambah'))]));
  }
  Future<void> checkout() async {
    if(cart.isEmpty)return;
    for(final e in cart.entries){final p=products.firstWhere((x)=>x.id==e.key);if(p.stock<e.value){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Stok '+p.name+' tidak cukup')));return;}}
    final cashController=TextEditingController(text:total.toString());
    String payment='Tunai';
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Pembayaran'),
      content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Total tagihan',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:4),
        Text(money.format(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:24,color:Color(0xFF137C5A))),
        const SizedBox(height:16),
        DropdownButtonFormField<String>(value:payment,decoration:const InputDecoration(labelText:'Metode pembayaran'),items:const[
          DropdownMenuItem(value:'Tunai',child:Text('Tunai')),
          DropdownMenuItem(value:'QRIS',child:Text('QRIS')),
          DropdownMenuItem(value:'Transfer',child:Text('Transfer bank')),
          DropdownMenuItem(value:'E-Wallet',child:Text('E-Wallet'))
        ],onChanged:(v)=>refresh(()=>payment=v??'Tunai')),
        if(payment=='Tunai')...[
          const SizedBox(height:12),
          TextField(controller:cashController,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Uang diterima',prefixText:'Rp '))
        ]
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
        FilledButton(onPressed:(){
          final received=payment=='Tunai'?(int.tryParse(cashController.text)??0):total;
          if(received<total){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Uang diterima masih kurang')));return;}
          Navigator.pop(ctx,true);
        },child:const Text('Selesaikan'))
      ]
    )));
    if(confirmed!=true)return;
    final received=payment=='Tunai'?(int.tryParse(cashController.text)??0):total;
    final paidTotal=total;
    final lines=<Map<String,dynamic>>[];
    for(final e in cart.entries){final p=products.firstWhere((x)=>x.id==e.key);lines.add({'name':p.name,'qty':e.value,'price':p.price});p.stock-=e.value;}
    sales.insert(0,Sale(DateTime.now(),paidTotal,branch,lines,payment:payment,cashReceived:received));
    cart.clear();await save();setState(()=>tab=0);
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Transaksi berhasil • Kembalian: '+money.format(received-paidTotal))));
  }

  Widget stat(String title,String value,IconData icon)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:const Color(0xFF137C5A),size:26),const SizedBox(height:12),Text(title,style:const TextStyle(color:Colors.black54,fontSize:12)),
    const SizedBox(height:4),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17),maxLines:1,overflow:TextOverflow.ellipsis)
  ]))));
  Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF126B50),Color(0xFF23966D)])),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SELAMAT DATANG',style:TextStyle(color:Colors.white70,letterSpacing:1.2,fontSize:11)),const SizedBox(height:8),
        const Text('Sri Rahayu POS',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(branch,style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:18),const Text('Kelola penjualan usaha Anda dengan mudah',style:TextStyle(color:Colors.white))])),
    const SizedBox(height:16),Row(children:[stat('Penjualan hari ini',money.format(todaySales),Icons.payments_outlined),const SizedBox(width:10),stat('Transaksi hari ini',todayCount.toString(),Icons.receipt_long)]),
    const SizedBox(height:18),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Transaksi terbaru',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),TextButton(onPressed:()=>setState(()=>tab=3),child:const Text('Lihat semua'))]),
    ...branchSales.take(5).map((s)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt)),title:Text(money.format(s.total),style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(DateFormat('dd MMM yyyy • HH:mm','id_ID').format(s.date)+' • '+s.payment),trailing:Text(s.items.length.toString()+' menu')))),
    if(branchSales.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Belum ada transaksi. Silakan mulai dari menu Kasir.')))
  ]);

  Widget cashier()=>Column(children:[
    Padding(padding:const EdgeInsets.all(14),child:Row(children:[Expanded(child:Text('Menu • '+branch,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))),Text(cart.values.fold(0,(a,b)=>a+b).toString()+' item')])),
    Expanded(child:GridView.builder(padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.9,crossAxisSpacing:10,mainAxisSpacing:10),
      itemCount:products.length,itemBuilder:(ctx,i){final p=products[i],q=cart[p.id]??0;return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:p.stock<=q?null:()=>setState(()=>cart[p.id]=q+1),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:SizedBox(width:double.infinity,child:p.image.isNotEmpty&&File(p.image).existsSync()?Image.file(File(p.image),fit:BoxFit.cover):Container(color:const Color(0xFFE7F2EC),child:const Icon(Icons.restaurant,size:40,color:Color(0xFF39866A))))),
        Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),Text(money.format(p.price),style:const TextStyle(color:Color(0xFF137C5A),fontWeight:FontWeight.w600)),Text('Stok '+p.stock.toString()+(q>0?' • Dipilih '+q.toString():''),style:const TextStyle(fontSize:11,color:Colors.black54))]))
      ])));})),
    Container(padding:const EdgeInsets.all(14),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(18))),child:Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Total pembayaran',style:TextStyle(fontWeight:FontWeight.w600)),Text(money.format(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20,color:Color(0xFF137C5A)))]),
      const SizedBox(height:10),Row(children:[Expanded(child:OutlinedButton(onPressed:cart.isEmpty?null:()=>setState(()=>cart.clear()),child:const Text('Kosongkan'))),const SizedBox(width:10),Expanded(flex:2,child:FilledButton.icon(onPressed:cart.isEmpty?null:checkout,icon:const Icon(Icons.check),label:const Text('Bayar sekarang')))])
    ]))
  ]);

  Widget menuPage()=>Scaffold(backgroundColor:Colors.transparent,floatingActionButton:FloatingActionButton.extended(onPressed:addProduct,icon:const Icon(Icons.add),label:const Text('Tambah menu')),
    body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:products.length,itemBuilder:(ctx,i){final p=products[i];return Card(child:ListTile(
      leading:ClipRRect(borderRadius:BorderRadius.circular(9),child:SizedBox(width:52,height:52,child:p.image.isNotEmpty&&File(p.image).existsSync()?Image.file(File(p.image),fit:BoxFit.cover):Container(color:const Color(0xFFE7F2EC),child:const Icon(Icons.restaurant)))),
      title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(p.category+' • '+money.format(p.price)+' • Stok '+p.stock.toString()),
      trailing:PopupMenuButton<String>(onSelected:(v){if(v=='stock')changeStock(p);if(v=='delete')setState(()=>products.remove(p));save();},itemBuilder:(_)=>const[PopupMenuItem(value:'stock',child:Text('Ubah stok')),PopupMenuItem(value:'delete',child:Text('Hapus menu'))])
    ));}));
  Widget reports()=>ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Total penjualan tercatat',style:TextStyle(color:Colors.black54)),const SizedBox(height:8),Text(money.format(branchSales.fold(0,(a,s)=>a+s.total)),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:25,color:Color(0xFF137C5A))),Text(branchSales.length.toString()+' transaksi • '+branch)]))),
    const SizedBox(height:12),const Text('Riwayat transaksi',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
    ...branchSales.map((s)=>Card(child:ExpansionTile(leading:const Icon(Icons.receipt_long,color:Color(0xFF137C5A)),title:Text(money.format(s.total),style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(DateFormat('dd MMM yyyy • HH:mm','id_ID').format(s.date)+' • '+s.payment),
      children:s.items.map((e)=>ListTile(dense:true,title:Text(e['name'].toString()),trailing:Text(e['qty'].toString()+' x '+money.format((e['price'] as num).toInt())))).toList()))),
    if(branchSales.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Belum ada transaksi di cabang ini')))
  ]);
  Widget expensePage()=>Scaffold(
    backgroundColor:Colors.transparent,
    floatingActionButton:FloatingActionButton.extended(onPressed:addExpense,icon:const Icon(Icons.add),label:const Text('Catat biaya')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Total pengeluaran cabang ini',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:8),
        Text(money.format(expenses.where((e)=>e.branch==branch).fold(0,(a,e)=>a+e.amount)),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:24,color:Color(0xFFB45309))),
        Text(expenses.where((e)=>e.branch==branch).length.toString()+' catatan biaya')
      ]))),
      const SizedBox(height:12),
      ...expenses.where((e)=>e.branch==branch).map((e)=>Card(child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.receipt_long)),
        title:Text(e.category,style:const TextStyle(fontWeight:FontWeight.bold)),
        subtitle:Text(DateFormat('dd MMM yyyy • HH:mm','id_ID').format(e.date)+(e.note.isEmpty?'':' • '+e.note)),
        trailing:Text(money.format(e.amount),style:const TextStyle(fontWeight:FontWeight.bold))
      ))),
      if(expenses.where((e)=>e.branch==branch).isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Belum ada pengeluaran di cabang ini')))
    ])
  );

  Widget branchPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Kelola lokasi usaha',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),const SizedBox(height:5),const Text('Pilih cabang aktif untuk melihat transaksi cabang tersebut.',style:TextStyle(color:Colors.black54)),const SizedBox(height:12),
    ...branches.map((b)=>Card(child:RadioListTile<String>(value:b,groupValue:branch,onChanged:(v){if(v==null)return;setState((){branch=v;cart.clear();});save();},title:Text(b,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(sales.where((s)=>s.branch==b).length.toString()+' transaksi'),secondary:const Icon(Icons.store,color:Color(0xFF137C5A))))),
    OutlinedButton.icon(onPressed:addBranch,icon:const Icon(Icons.add_business),label:const Text('Tambah cabang')),
    const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('Catatan: data versi ini tersimpan di HP. Sinkronisasi otomatis antarperangkat/cabang belum tersedia.')))
  ]);

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[dashboard(),cashier(),menuPage(),reports(),branchPage(),expensePage(),staffPage()];
    const titles=['Ringkasan','Kasir','Daftar Menu','Laporan','Cabang','Pengeluaran','Gaji & Kasbon'];
    return Scaffold(appBar:AppBar(title:Row(children:[Container(width:36,height:36,decoration:BoxDecoration(color:const Color(0xFF137C5A),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.storefront,color:Colors.white)),
      const SizedBox(width:9),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(titles[tab],style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),Text(branch,style:const TextStyle(fontSize:11,color:Colors.black54))])]),
      actions:[PopupMenuButton<String>(onSelected:(v){if(v=='password')changeLoginPassword();if(v=='logout')logout();},itemBuilder:(_)=>const[PopupMenuItem(value:'password',child:Text('Ubah kata sandi')),PopupMenuItem(value:'logout',child:Text('Keluar akun'))])]),
      body:IndexedStack(index:tab,children:pages),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Home'),
        NavigationDestination(icon:Icon(Icons.point_of_sale_outlined),selectedIcon:Icon(Icons.point_of_sale),label:'Kasir'),
        NavigationDestination(icon:Icon(Icons.restaurant_menu),label:'Menu'),
        NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'Laporan'),
        NavigationDestination(icon:Icon(Icons.store_outlined),selectedIcon:Icon(Icons.store),label:'Cabang'),
        NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet),label:'Biaya'),
        NavigationDestination(icon:Icon(Icons.groups_outlined),selectedIcon:Icon(Icons.groups),label:'Karyawan')
      ]));
  }
}

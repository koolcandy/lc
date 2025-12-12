import 'package:flutter/material.dart';
import '../data/models/appointment.dart';
import '../data/services/api_service.dart';
import 'appointment_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Appointment> _data = [];
  bool _isLoading = true;
  int _page = 1;
  bool _isBottom = false; // 是否已加载完所有数据
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _fetchData(1);
    
    // 监听滚动到底部
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (!_isBottom && !_isLoading) {
          _fetchData(_page + 1);
        }
      }
    });
  }

  Future<void> _fetchData(int pageNumber, {bool refresh = false}) async {
    if (!refresh) {
      setState(() => _isLoading = true);
    }

    try {
      final newData = await ApiService().fetchAppointments(
        currentPage: pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _data = newData;
          } else {
            _data.addAll(newData);
          }
          
          _page = pageNumber;
          _isBottom = newData.length < _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchData(1, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的预约')),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _data.isEmpty && !_isLoading
            ? ListView(children: const [
                SizedBox(height: 200),
                Center(child: Text('暂无预约记录')),
              ])
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _data.length + 1, // +1 for loading/footer
                itemBuilder: (context, index) {
                  if (index == _data.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: _isBottom 
                            ? const Text('已经到底了', style: TextStyle(color: Colors.grey))
                            : const CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  return AppointmentCard(
                    appointment: _data[index],
                    onRefresh: _onRefresh,
                  );
                },
              ),
      ),
    );
  }
}
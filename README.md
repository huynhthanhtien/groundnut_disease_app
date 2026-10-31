# Bệnh Lạc — nhận diện bệnh cây lạc từ ảnh

Ứng dụng Flutter (Android) chụp/chọn ảnh lá hoặc quả lạc, nhận diện bệnh bằng
mô hình YOLOv8 xuất sang TFLite (chạy hoàn toàn trên máy, không cần mạng), và
đưa ra hướng dẫn xử lý.

## Tính năng

- **Quét**: chụp ảnh hoặc chọn từ thư viện → khung vùng bệnh trên ảnh, tên bệnh
  tiếng Việt, độ tin cậy, mức lan ước tính. Kết quả dưới 50% hiện là
  "Chưa chắc chắn" kèm mẹo chụp lại. Nếu ảnh có thêm bệnh khác đủ tin cậy
  (vd. gỉ sắt cùng đốm lá), mục "Cũng phát hiện trên ảnh" liệt kê và dẫn sang
  cách xử lý từng bệnh.
- **Bệnh hại**: thư viện 6 nhóm bệnh model nhận diện được — triệu chứng, dễ nhầm
  với, điều kiện phát sinh, cần làm ngay, hoạt chất tham khảo, phòng ngừa, khi
  nào gọi chuyên gia.
- **Lịch sử**: lưu kết quả (kèm ghi chú ruộng/luống, sửa được sau) trên máy,
  lọc, tìm theo ghi chú/tên bệnh (gõ không dấu cũng được), vuốt để xóa.
- Chia sẻ ảnh kết quả có khung bệnh; phóng to ảnh; gọi trạm khuyến nông (số do
  người dùng nhập).

## Cấu trúc

```
lib/
  data/disease_info.dart      Nội dung bệnh (tiếng Việt) + mẹo chụp + miễn trừ
  services/
    yolo_model_service.dart   Tải model, chạy suy luận trên isolate nền
    image_preprocessor.dart   Letterbox 640x640 → Float32List NCHW
    yolo_postprocess.dart     Giải mã output [1, 10, 8400] + NMS
    scan_analysis.dart        Kết quả chính, ngưỡng tin cậy, độ phủ, mức lan
    history_store.dart        Lịch sử lưu ở <documents>/history (JSON + ảnh)
    app_settings.dart         Onboarding, số trạm khuyến nông
  screens/                    main_shell (3 tab), home, result, disease_detail,
                              disease_library, history, onboarding
  utils/box_mapping.dart      Đổi toạ độ khung ảnh → widget (BoxFit.cover/contain)
  utils/text_search.dart      Tìm kiếm bỏ dấu tiếng Việt
assets/models/                best_fp32.tflite, labels.txt
```

Model được huấn luyện/xuất trong repo `android_Computer-vision`
(`scripts/export.py`). Thứ tự nhãn trong `labels.txt` phải khớp với model.

## Chạy

```bash
flutter pub get
flutter run            # cần thiết bị Android
flutter test           # unit + widget test
flutter test integration_test/batch_eval_test.dart   # chạy model thật trên thiết bị
```

## Nội dung cần duyệt

Toàn bộ nội dung trong `lib/data/disease_info.dart` là bản nháp tham khảo, **chưa
được chuyên gia BVTV duyệt**. Khi duyệt xong, đặt `kContentReviewed = true` và cập
nhật `kContentUpdated` — banner "Nội dung đang chờ chuyên gia duyệt" sẽ tự ẩn.
Thuốc chỉ ghi theo hoạt chất; cần đối chiếu với danh mục thuốc BVTV được phép sử
dụng tại Việt Nam hiện hành.

## Giới hạn đã biết

- "Mức lan" là ước tính từ số vùng và diện tích khung (model không phân đoạn vết
  bệnh), ngưỡng trong `severityFor()` cần hiệu chỉnh với mẫu thực địa.
- Model chưa có lớp "lá khỏe" và "không phải lá lạc" nên ảnh không liên quan vẫn
  có thể cho kết quả; ngưỡng "chưa chắc chắn" giúp giảm nhưng không loại bỏ.

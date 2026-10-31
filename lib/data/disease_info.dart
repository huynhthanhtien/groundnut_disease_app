/// Disease reference content shown on the result, detail and library
/// screens, keyed by the model's class names (assets/models/labels.txt).
///
/// This is general agronomy guidance drafted for review — it is not a
/// substitute for a local plant-protection / extension officer, and the UI
/// always pairs it with that disclaimer. Pesticides are listed by *active
/// ingredient* only; users must pick a registered product from Vietnam's
/// current "Danh mục thuốc BVTV được phép sử dụng" and follow its label.
library;

/// Flip to true once an agronomist has reviewed every entry below. While
/// false, detail screens show a "nội dung đang chờ chuyên gia duyệt" banner.
const bool kContentReviewed = false;

/// Shown as "Cập nhật nội dung" on detail screens.
const String kContentUpdated = '28/10/2026';

enum PlantPart { leaf, pod, stem }

extension PlantPartLabel on PlantPart {
  String get label {
    switch (this) {
      case PlantPart.leaf:
        return 'Lá';
      case PlantPart.pod:
        return 'Quả / hạt';
      case PlantPart.stem:
        return 'Gốc / cổ rễ';
    }
  }
}

class AdviceStep {
  final String title;
  final String body;

  const AdviceStep(this.title, this.body);
}

class DiseaseInfo {
  /// Model class name, as in labels.txt.
  final String label;
  final String displayName;
  final String scientificName;
  final PlantPart part;

  /// One-sentence overview for list tiles and the result screen.
  final String summary;
  final List<String> symptoms;
  final List<String> conditions;
  final List<String> confusedWith;

  /// What to do now, in order.
  final List<AdviceStep> steps;
  final List<String> activeIngredients;
  final List<String> prevention;
  final List<String> callExpertWhen;

  /// Prominent safety warning (e.g. aflatoxin), if any.
  final String? warning;

  const DiseaseInfo({
    required this.label,
    required this.displayName,
    required this.scientificName,
    required this.part,
    required this.summary,
    required this.symptoms,
    required this.conditions,
    required this.confusedWith,
    required this.steps,
    required this.activeIngredients,
    required this.prevention,
    required this.callExpertWhen,
    this.warning,
  });
}

/// Reminder appended wherever [DiseaseInfo.activeIngredients] are listed.
const String kPesticideNote =
    'Chỉ là hoạt chất tham khảo. Chọn sản phẩm có trong danh mục thuốc BVTV được phép sử dụng tại Việt Nam, '
    'đọc kỹ nhãn, dùng đúng liều, đúng thời gian cách ly trước thu hoạch và mang đồ bảo hộ khi phun. '
    'Luân phiên các nhóm hoạt chất khác nhau để nấm không kháng thuốc.';

const List<DiseaseInfo> kDiseases = [
  DiseaseInfo(
    label: 'Early and Late leaf spot',
    displayName: 'Đốm lá sớm / đốm lá muộn',
    scientificName: 'Passalora arachidicola, Nothopassalora personata',
    part: PlantPart.leaf,
    summary:
        'Hai bệnh nấm phổ biến nhất trên lạc. Lá bị đốm nâu đen, rụng sớm, có thể làm giảm năng suất rõ rệt nếu không xử lý.',
    symptoms: [
      'Đốm sớm: đốm tròn màu nâu đến nâu đỏ, đường kính khoảng 1–10 mm, thường có quầng vàng rõ quanh đốm; mặt dưới lá màu nhạt hơn mặt trên.',
      'Đốm muộn: đốm nhỏ hơn, tròn đều, màu nâu sẫm đến đen ở cả hai mặt lá; mặt dưới có nhiều chấm đen nhỏ (ổ bào tử); quầng vàng mờ hoặc không có.',
      'Bệnh thường bắt đầu từ lá già phía dưới rồi lan dần lên trên.',
      'Bệnh nặng: nhiều đốm liên kết thành mảng, lá vàng và rụng hàng loạt, cây trơ cành trước thu hoạch.',
    ],
    conditions: [
      'Ẩm độ cao, mưa nhiều, sương đêm kéo dài; nhiệt độ khoảng 25–30 °C.',
      'Đốm sớm hay xuất hiện từ khoảng 30–50 ngày sau gieo; đốm muộn thường xuất hiện muộn hơn, từ giai đoạn ra hoa – làm quả.',
      'Nguồn bệnh tồn tại trên tàn dư cây lạc vụ trước và lạc mọc tự nhiên ngoài ruộng.',
      'Trồng lạc liên tục, trồng quá dày làm tán lá bí, ẩm.',
    ],
    confusedWith: [
      'Gỉ sắt: có mụn nhỏ màu cam/nâu đỏ nổi lên ở mặt dưới lá, quệt tay thấy bột màu gỉ — đốm lá thì không có bột.',
      'Hai bệnh đốm lá và gỉ sắt thường xuất hiện cùng lúc trên một ruộng.',
    ],
    steps: [
      AdviceStep('Kiểm tra mức độ',
          'Đi theo đường chéo ruộng, xem lá ở tầng dưới của khoảng 10–20 cây. Ghi lại tỷ lệ lá có đốm để theo dõi.'),
      AdviceStep('Giảm nguồn bệnh',
          'Ngắt bỏ lá bệnh nặng ở tầng dưới (nếu diện tích nhỏ), gom ra khỏi ruộng và tiêu hủy; không vứt lại bờ ruộng.'),
      AdviceStep('Phun thuốc khi bệnh mới chớm',
          'Phun sớm hiệu quả hơn nhiều so với khi lá đã rụng. Phun ướt đều cả hai mặt lá, nhất là tầng lá dưới. Nếu thời tiết tiếp tục ẩm, phun nhắc lại sau khoảng 10–14 ngày theo hướng dẫn trên nhãn.'),
      AdviceStep('Theo dõi sau phun',
          'Chụp lại cùng vị trí sau 7–10 ngày. Nếu đốm mới vẫn xuất hiện nhiều, đổi sang thuốc khác nhóm hoạt chất.'),
    ],
    activeIngredients: [
      'Nhóm bảo vệ (phun phòng / khi chớm bệnh): chlorothalonil, mancozeb',
      'Nhóm triazole (lưu dẫn): hexaconazole, tebuconazole, difenoconazole, propiconazole',
      'Nhóm strobilurin (thường phối hợp sẵn với triazole): azoxystrobin',
    ],
    prevention: [
      'Luân canh 2–3 năm với lúa, ngô hoặc cây không phải họ đậu.',
      'Thu gom, cày vùi sâu hoặc tiêu hủy tàn dư cây lạc sau thu hoạch; nhổ lạc mọc tự nhiên.',
      'Dùng giống có khả năng chống chịu bệnh lá được khuyến cáo tại địa phương.',
      'Gieo đúng mật độ, lên luống thoát nước, không để ruộng quá rậm.',
      'Bón phân cân đối, đủ lân và kali, bổ sung vôi; không bón thừa đạm.',
    ],
    callExpertWhen: [
      'Trên 1/3 số lá của cây có đốm, hoặc lá bắt đầu rụng hàng loạt.',
      'Đã phun 2 lần mà bệnh vẫn lan nhanh.',
      'Không chắc là đốm lá hay bệnh khác.',
    ],
  ),
  DiseaseInfo(
    label: 'Rust-Leaf',
    displayName: 'Bệnh gỉ sắt',
    scientificName: 'Puccinia arachidis',
    part: PlantPart.leaf,
    summary:
        'Bệnh nấm lây lan nhanh theo gió, tạo mụn bột màu gỉ sắt ở mặt dưới lá. Bệnh nặng làm lá khô cháy, hạt lép.',
    symptoms: [
      'Mặt dưới lá có các mụn nhỏ (khoảng 0,5–1 mm) màu cam đến nâu đỏ, nổi gồ lên; mụn vỡ ra lớp bột màu gỉ sắt, quệt tay thấy dính bột.',
      'Mặt trên lá tương ứng có các chấm vàng nhạt.',
      'Bệnh có thể xuất hiện cả trên cuống lá và thân.',
      'Bệnh nặng: lá vàng, khô cháy nhưng thường vẫn dính trên cây (khác với đốm lá hay làm rụng lá).',
    ],
    conditions: [
      'Ẩm độ không khí cao (trên khoảng 85%), mưa phùn, sương nhiều; nhiệt độ khoảng 20–28 °C.',
      'Bào tử phát tán xa theo gió và nước mưa, bệnh có thể lan cả cánh đồng trong vài tuần.',
      'Lạc mọc tự nhiên giữa hai vụ là nơi giữ nguồn bệnh.',
    ],
    confusedWith: [
      'Đốm lá: đốm nâu đen phẳng, không có bột màu cam khi quệt tay.',
      'Lật mặt dưới lá để kiểm tra trước khi kết luận.',
    ],
    steps: [
      AdviceStep('Xác nhận bệnh',
          'Lật mặt dưới lá, tìm mụn bột màu cam/nâu đỏ. Chụp thêm một ảnh mặt dưới lá để app kiểm tra lại.'),
      AdviceStep('Phun thuốc sớm',
          'Gỉ sắt lan rất nhanh — nên phun ngay khi thấy những mụn đầu tiên. Phun kỹ mặt dưới lá. Phun nhắc lại theo hướng dẫn trên nhãn nếu trời còn ẩm.'),
      AdviceStep('Báo cho ruộng bên cạnh',
          'Bào tử bay theo gió, nên báo cho các hộ trồng lạc xung quanh để cùng kiểm tra và xử lý.'),
      AdviceStep('Thu gom tàn dư',
          'Sau thu hoạch, gom và tiêu hủy thân lá bệnh; không để lạc mọc tự nhiên trên ruộng.'),
    ],
    activeIngredients: [
      'Nhóm triazole: hexaconazole, propiconazole, tebuconazole, difenoconazole',
      'Nhóm bảo vệ (phun phòng): mancozeb, chlorothalonil',
      'Thuốc nhóm triazole thường trị được cả gỉ sắt và đốm lá khi hai bệnh xuất hiện cùng lúc.',
    ],
    prevention: [
      'Dùng giống chống chịu gỉ sắt được khuyến cáo tại địa phương.',
      'Gieo trồng tập trung, đúng thời vụ của vùng để tránh giai đoạn ẩm cao kéo dài.',
      'Nhổ bỏ lạc mọc tự nhiên giữa hai vụ.',
      'Luân canh với cây khác họ; bón cân đối, không thừa đạm.',
    ],
    callExpertWhen: [
      'Bệnh xuất hiện trên diện rộng hoặc nhiều ruộng xung quanh cùng bị.',
      'Lá tầng giữa và tầng trên đã có nhiều mụn gỉ.',
      'Đã phun mà mụn mới vẫn tiếp tục xuất hiện.',
    ],
  ),
  DiseaseInfo(
    label: 'black fungus-grondnut',
    displayName: 'Thối cổ rễ (mốc đen)',
    scientificName: 'Aspergillus niger',
    part: PlantPart.stem,
    summary:
        'Bệnh nấm trong đất gây thối cổ rễ, làm cây con héo rũ và chết, có lớp mốc bột màu đen ở gốc. Thường gặp ở giai đoạn cây con.',
    symptoms: [
      'Cây con héo rũ đột ngột, lá vẫn còn xanh lúc đầu rồi khô dần.',
      'Phần cổ rễ (sát mặt đất) bị thối, teo tóp, phủ một lớp mốc bột màu đen.',
      'Hạt có thể bị thối ngay khi nảy mầm, gây mất khoảng trên luống.',
      'Nhổ cây lên thấy phần vỏ cổ rễ mủn, dễ tuột.',
    ],
    conditions: [
      'Hạt giống chất lượng kém, vỏ lụa bị trầy xước hoặc đã nhiễm mốc từ khi bảo quản.',
      'Đất nóng, xen kẽ khô – ẩm; gieo quá sâu làm cây mọc chậm.',
      'Đất có nhiều tàn dư hữu cơ chưa hoai mục; trồng lạc liên tục nhiều vụ.',
    ],
    confusedWith: [
      'Héo xanh vi khuẩn: cây héo nhưng không có mốc đen ở gốc; cắt ngang thân ngâm vào cốc nước trong thấy dịch vi khuẩn màu trắng đục chảy ra.',
      'Thối gốc mốc trắng: ở gốc có sợi nấm trắng và hạch nấm tròn nhỏ như hạt cải.',
    ],
    steps: [
      AdviceStep('Nhổ bỏ cây bệnh',
          'Nhổ cả cây và đất bám quanh rễ, cho vào bao mang ra khỏi ruộng tiêu hủy. Không vứt lại trên ruộng hoặc kênh mương.'),
      AdviceStep('Xử lý chỗ cây bệnh',
          'Rắc một ít vôi bột vào hốc vừa nhổ để hạn chế nấm lan sang cây bên cạnh.'),
      AdviceStep('Bảo vệ cây còn lại',
          'Có thể tưới gốc bằng chế phẩm nấm đối kháng Trichoderma, hoặc thuốc trừ nấm đất theo khuyến cáo của cán bộ BVTV.'),
      AdviceStep('Gieo dặm',
          'Nếu mất khoảng nhiều, gieo dặm bằng hạt đã được xử lý trước để đảm bảo mật độ.'),
    ],
    activeIngredients: [
      'Xử lý hạt giống trước khi gieo: thuốc xử lý hạt có đăng ký cho lạc (theo khuyến cáo địa phương)',
      'Sinh học: chế phẩm Trichoderma spp. trộn phân chuồng hoai bón lót hoặc tưới gốc',
      'Tưới gốc khi bệnh lan: hỏi cán bộ BVTV về hoạt chất phù hợp đang được phép sử dụng',
    ],
    prevention: [
      'Dùng hạt giống chắc mẩy, không sứt vỏ lụa, không bị mốc; bóc vỏ gần ngày gieo.',
      'Xử lý hạt giống bằng thuốc hoặc chế phẩm sinh học trước khi gieo.',
      'Gieo đúng độ sâu (khoảng 3–5 cm), đủ ẩm để cây mọc nhanh.',
      'Bón phân chuồng đã hoai mục, ủ cùng Trichoderma.',
      'Luân canh với lúa nước — ngập nước giúp giảm nguồn nấm trong đất.',
    ],
    callExpertWhen: [
      'Tỷ lệ cây chết vượt khoảng 5–10% hoặc tiếp tục tăng sau khi đã xử lý.',
      'Không thấy mốc đen ở gốc (có thể là bệnh héo khác).',
    ],
  ),
  DiseaseInfo(
    label: 'Black Fungus Pod',
    displayName: 'Mốc đen quả / hạt',
    scientificName: 'Aspergillus niger',
    part: PlantPart.pod,
    summary:
        'Nấm mốc đen phát triển trên vỏ quả và hạt, thường do quả bị ẩm khi còn trong đất, khi phơi hoặc khi bảo quản.',
    warning:
        'Hạt lạc bị mốc (nhất là mốc màu vàng xanh) có thể chứa độc tố aflatoxin gây hại gan và gây ung thư, rang nấu cũng không hết độc. '
        'KHÔNG ăn, KHÔNG ép dầu, KHÔNG bán và KHÔNG cho gia súc, gia cầm ăn hạt bị mốc.',
    symptoms: [
      'Vỏ quả có lớp mốc bột màu đen, có thể kèm vết thâm.',
      'Bóc vỏ thấy hạt bị mốc đen, teo, nhăn hoặc đổi màu.',
      'Quả bị mốc thường nhẹ hơn, có mùi mốc khi để chung.',
    ],
    conditions: [
      'Thu hoạch muộn, quả quá chín nằm lâu trong đất ẩm.',
      'Quả bị nứt, trầy xước khi nhổ, khi tuốt hoặc do côn trùng đất cắn.',
      'Phơi không kịp khô, để đống ẩm qua đêm, bảo quản nơi ẩm thấp.',
      'Cây bị hạn cuối vụ rồi gặp mưa cũng làm quả dễ nhiễm mốc.',
    ],
    confusedWith: [
      'Mốc vàng xanh (Aspergillus flavus): lớp mốc màu vàng lục — nguy cơ aflatoxin rất cao, xử lý như trên.',
      'Thối quả nâu: vỏ quả có vết nâu, mềm thối, ít bột mốc đen.',
    ],
    steps: [
      AdviceStep('Tách riêng quả bị mốc',
          'Nhặt riêng toàn bộ quả mốc, quả nứt, quả lép ra khỏi lô lạc; không để lẫn với quả lành.'),
      AdviceStep('Tiêu hủy quả mốc',
          'Đốt hoặc chôn sâu quả bị mốc. Không dùng làm thức ăn chăn nuôi, không ép dầu.'),
      AdviceStep('Phơi khô nhanh phần còn lại',
          'Phơi trên sân/bạt sạch, lớp mỏng, đảo thường xuyên cho đến khi hạt đạt độ ẩm an toàn (khoảng dưới 9%; cắn hạt thấy giòn, vỏ lụa dễ bong).'),
      AdviceStep('Bảo quản khô thoáng',
          'Đựng trong bao sạch, kín, kê cao cách nền và tường; kiểm tra định kỳ, phơi lại nếu thấy ẩm.'),
    ],
    activeIngredients: [
      'Không có thuốc chữa cho quả/hạt đã bị mốc — biện pháp chính là loại bỏ và phơi sấy đúng cách.',
      'Ngoài đồng: có thể dùng chế phẩm Trichoderma bón vào đất để giảm nguồn nấm cho vụ sau.',
    ],
    prevention: [
      'Thu hoạch đúng lúc (khi khoảng 70–80% quả có vỏ cứng, mặt trong vỏ có vân sẫm), tránh để quá chín.',
      'Nhổ, tuốt nhẹ tay để không làm nứt vỏ quả.',
      'Phơi ngay trong ngày thu hoạch, không để đống ẩm qua đêm.',
      'Bón vôi hoặc thạch cao giai đoạn ra hoa để vỏ quả chắc, ít nứt.',
      'Tưới đủ ẩm cuối vụ nếu gặp hạn để tránh nứt quả.',
    ],
    callExpertWhen: [
      'Tỷ lệ quả mốc lớn trong lô hàng định bán hoặc làm giống.',
      'Thấy mốc màu vàng xanh trên hạt.',
    ],
  ),
  DiseaseInfo(
    label: 'brown Fungus Pod',
    displayName: 'Thối quả nâu',
    scientificName: 'Fusarium spp., Rhizoctonia solani, Pythium spp. (thường do nhiều loại nấm đất)',
    part: PlantPart.pod,
    summary:
        'Quả lạc bị thối vỏ, có vết nâu sẫm và hạt bị hỏng ngay khi còn trong đất. Thường gặp ở đất ẩm, thiếu canxi.',
    warning: 'Hạt từ quả thối có thể nhiễm nấm mốc — không ăn và không làm giống.',
    symptoms: [
      'Vỏ quả có vết nâu đến nâu đen, lúc đầu là chấm nhỏ rồi lan rộng.',
      'Vỏ quả mềm, mủn, dễ vỡ; hạt bên trong biến màu, teo hoặc thối.',
      'Phần thân lá phía trên thường vẫn xanh bình thường nên khó phát hiện sớm — cần đào thử vài cây.',
    ],
    conditions: [
      'Đất úng nước, thoát nước kém, đất nặng, đất chua.',
      'Thiếu canxi trong giai đoạn đâm tia, làm quả.',
      'Quả bị tổn thương do côn trùng đất, tuyến trùng hoặc khi xới xáo.',
      'Trồng lạc liên tục nhiều vụ.',
    ],
    confusedWith: [
      'Mốc đen quả: có lớp bột mốc màu đen rõ trên vỏ.',
      'Vỏ quả sẫm màu tự nhiên khi chín già — vỏ vẫn cứng, hạt bên trong bình thường.',
    ],
    steps: [
      AdviceStep('Đào kiểm tra',
          'Đào thử 5–10 cây ở các vị trí khác nhau trong ruộng để ước lượng tỷ lệ quả thối.'),
      AdviceStep('Tháo nước, giữ ruộng thông thoáng',
          'Khơi rãnh thoát nước ngay nếu ruộng bị đọng nước; tránh tưới tràn.'),
      AdviceStep('Thu hoạch sớm nếu bệnh nặng',
          'Khi quả đã gần già mà tỷ lệ thối tăng nhanh, cân nhắc thu hoạch sớm để giảm thiệt hại.'),
      AdviceStep('Phân loại khi thu hoạch',
          'Loại bỏ quả thối, quả đổi màu; phơi khô nhanh phần quả lành.'),
    ],
    activeIngredients: [
      'Sinh học: chế phẩm Trichoderma bón vào đất cùng phân chuồng hoai',
      'Hóa học: hỏi cán bộ BVTV về thuốc trừ nấm đất phù hợp, vì bệnh do nhiều loại nấm khác nhau gây ra',
    ],
    prevention: [
      'Bón vôi khi làm đất (đất chua) và bón thạch cao hoặc vôi giai đoạn ra hoa – đâm tia để cung cấp canxi cho quả.',
      'Lên luống cao, có rãnh thoát nước tốt.',
      'Luân canh với lúa, ngô; không trồng lạc hoặc cây họ đậu liên tục.',
      'Hạn chế xới xáo làm tổn thương quả ở giai đoạn làm quả; phòng trừ côn trùng đất.',
    ],
    callExpertWhen: [
      'Tỷ lệ quả thối vượt khoảng 10% khi đào kiểm tra.',
      'Ruộng bị bệnh lặp lại qua nhiều vụ.',
    ],
  ),
  DiseaseInfo(
    label: 'Fungus leaf',
    displayName: 'Bệnh nấm lá (chưa xác định rõ)',
    scientificName: 'Chưa định danh — có thể là một trong nhiều loại nấm gây hại lá',
    part: PlantPart.leaf,
    summary:
        'Lá có dấu hiệu nhiễm nấm nhưng chưa xác định được bệnh cụ thể. Nên chụp thêm ảnh và so sánh với các bệnh lá đã biết.',
    symptoms: [
      'Lá có vết bệnh, đốm hoặc mảng đổi màu không giống hẳn đốm lá hay gỉ sắt.',
      'Có thể là giai đoạn sớm của một bệnh lá khác, hoặc nhiều bệnh xuất hiện cùng lúc.',
    ],
    conditions: [
      'Thời tiết ẩm, mưa nhiều; ruộng trồng dày, ít thông thoáng.',
      'Tàn dư cây trồng vụ trước còn trên ruộng.',
    ],
    confusedWith: [
      'Đốm lá sớm / muộn, gỉ sắt, cháy lá, đốm lá do thiếu dinh dưỡng hoặc cháy do thuốc.',
      'Hãy mở mục "Bệnh hại" trong app để so sánh triệu chứng.',
    ],
    steps: [
      AdviceStep('Chụp lại rõ hơn',
          'Chụp cận một lá bệnh điển hình, đủ sáng, chụp cả mặt trên và mặt dưới lá, rồi quét lại.'),
      AdviceStep('Cách ly khu vực bệnh',
          'Đánh dấu chỗ có cây bệnh, hạn chế đi lại khi lá còn ướt để tránh phát tán bào tử.'),
      AdviceStep('Vệ sinh đồng ruộng',
          'Ngắt bỏ lá bệnh nặng, dọn sạch tàn dư; tiêu hủy ngoài ruộng.'),
      AdviceStep('Hỏi ý kiến chuyên gia trước khi phun',
          'Vì chưa rõ bệnh, nên mang mẫu lá hoặc ảnh tới trạm khuyến nông/BVTV trước khi quyết định phun thuốc.'),
    ],
    activeIngredients: [
      'Chưa nên phun khi chưa rõ bệnh. Nếu được khuyến cáo phun, thuốc trừ nấm phổ rộng nhóm bảo vệ như mancozeb thường được dùng để phòng.',
    ],
    prevention: [
      'Luân canh, vệ sinh đồng ruộng, trồng đúng mật độ.',
      'Bón phân cân đối, không thừa đạm.',
      'Kiểm tra ruộng định kỳ 7–10 ngày một lần trong mùa mưa.',
    ],
    callExpertWhen: [
      'Bệnh lan nhanh hoặc không giống bệnh nào trong danh sách.',
    ],
  ),
];

final Map<String, DiseaseInfo> kDiseaseInfo = {for (final d in kDiseases) d.label: d};

DiseaseInfo? diseaseInfoFor(String className) => kDiseaseInfo[className];

/// Vietnamese name for a model class, falling back to the raw label.
String displayNameFor(String className) => kDiseaseInfo[className]?.displayName ?? className;

/// General photo-taking tips, shown in onboarding and on weak/empty results.
const List<AdviceStep> kPhotoTips = [
  AdviceStep('Chụp một lá hoặc một quả', 'Đưa một lá (hoặc quả) bệnh điển hình vào giữa khung, chiếm phần lớn ảnh.'),
  AdviceStep('Đủ sáng, không ngược sáng', 'Chụp dưới ánh sáng tự nhiên, tránh nắng gắt chói và bóng đổ che vết bệnh.'),
  AdviceStep('Giữ máy chắc tay', 'Đợi máy lấy nét rõ vết bệnh rồi mới bấm. Ảnh mờ sẽ cho kết quả kém.'),
  AdviceStep('Chụp cả mặt dưới lá', 'Nhiều bệnh (như gỉ sắt) thấy rõ nhất ở mặt dưới lá.'),
  AdviceStep('Chụp nhiều cây', 'Một ảnh chỉ đại diện cho một cây. Kiểm tra vài vị trí trong ruộng trước khi quyết định phun.'),
];

const String kDisclaimer =
    'Kết quả chỉ là gợi ý dựa trên hình ảnh, có thể sai. Trước khi phun thuốc trên diện rộng, '
    'hãy hỏi cán bộ khuyến nông hoặc bảo vệ thực vật địa phương. Luôn dùng thuốc đúng liều và đúng thời gian cách ly ghi trên nhãn.';

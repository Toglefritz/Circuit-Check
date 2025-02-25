import 'package:copper_app/services/kicad_parser/kicad_entity.dart';
import 'package:copper_app/services/kicad_parser/kicad_pcb_component.dart';
import 'package:copper_app/services/kicad_parser/kicad_pcb_layer.dart';
import 'package:copper_app/services/kicad_parser/kicad_pcb_net.dart';
import 'package:collection/collection.dart';

/// Represents a KiCAD PCB Design.
///
/// This class serves as the main data model for a parsed KiCAD PCB design file (`.kicad_pcb`). It encapsulates
/// key aspects of the design, including metadata (such as version and generator), layers, components (footprints),
/// and electrical connections (nets). The `KiCadPCBDesign` object is created by parsing an S-Expression formatted KiCAD
/// file and structuring the extracted data into a format that can be easily manipulated within the application.
///
/// ## Purpose
/// - This class provides an object-oriented representation of the PCB design.
/// - It allows efficient access and modification of the design data.
/// - It serves as the root data structure when analyzing and performing operations on the PCB.
///
/// ## Usage
/// The `KiCadPCBDesign` class is instantiated by the `KiCadPCBDesign.fromSExpr` factory method, which converts a
/// parsed S-Expression map into an organized PCB representation. Other components of the app, such as design analysis
/// Azure AI tools and visualization functions, rely on this class to access the PCBs structure and metadata.
// ignore_for_file: avoid_dynamic_calls
class KiCadPCBDesign extends KiCadEntity {
  /// Creates a new `KiCadPCBDesign` instance from the provided design data.
  ///
  /// This constructor is primarily used internally when parsing the KiCAD file but may also be used in testing or
  /// when manually constructing a PCB representation.
  KiCadPCBDesign({
    required this.version,
    required this.generator,
    required this.generatorVersion,
    required this.layers,
    required this.components,
    required this.nets,
  });

  /// The version number of the KiCAD file format used to create this PCB design.
  ///
  /// This indicates the schema version of the `.kicad_pcb` file. Different KiCAD versions may introduce changes in the
  /// file format, so this field helps ensure compatibility with the parser.
  final String? version;

  /// The software that generated this PCB design file.
  ///
  /// This field typically contains the name and version of the application (e.g., `"pcbnew"`) that produced the
  /// `.kicad_pcb` file. It helps track the toolchain used in the design process.
  final String? generator;

  /// The generator version of the KiCAD file format used to create this PCB design.
  final String? generatorVersion;

  /// The list of layers present in the PCB design.
  ///
  /// Each layer represents a physical or logical part of the PCB (e.g., copper layers, silkscreen, mask).
  /// This list includes user-defined layers and standard KiCAD layers, extracted from the S-Expression format.
  final List<KiCadPCBLayer> layers;

  /// The list of components (footprints) placed on the PCB.
  ///
  /// Components include resistors, capacitors, integrated circuits, and any other elements that are part of the
  /// circuit. This list stores each component's position, layer, and reference identifier.
  final List<KiCadPCBComponent> components;

  /// The list of electrical connections (nets) within the PCB.
  ///
  /// A net defines an electrical connection between components. This field contains all the named nets in the design,
  /// linking components through copper traces or other conductive elements.
  final List<KiCadPCBNet> nets;

  /// Creates a `KiCadPCBDesign` instance from a parsed S-Expression structure.
  ///
  /// This factory constructor takes a `Map<String, dynamic>` representation of the KiCAD S-Expression data and
  /// converts it into a structured `KiCadPCBDesign` object.
  ///
  /// This method is used within the KiCAD parser system to generate a usable PCB data model.
  factory KiCadPCBDesign.fromKiCadSExpr(Map<String, dynamic> data) {
    if (!data.containsKey('kicad_pcb') || data['kicad_pcb'] is! List) {
      throw const FormatException('Invalid KiCad PCB structure');
    }

    // Extract KiCAD design data from the parsed S-Expression structure.
    final List<dynamic> kiCadData = data['kicad_pcb'] as List;

    // Get the version from the parsed data. This will be the first item in the array for which the first element
    // is the string 'version'.
    final List<dynamic>? versionElement =
        kiCadData.firstWhereOrNull((dynamic element) => element.first == 'version') as List<dynamic>?;
    final String? version = versionElement?.elementAt(1) as String?;

    // Get the generator from the parsed data. This will be the first item in the array for which the first element
    // is the string 'generator'.
    final List<dynamic>? generatorElement =
        kiCadData.firstWhereOrNull((dynamic element) => element.first == 'generator') as List<dynamic>?;
    final String? generator = generatorElement?.elementAt(1) as String?;

    // Get the generator version from the parsed data. This will be the first item in the array for which the first element
    // is the string 'generator_version'.
    final List<dynamic>? generatorVersionElement =
        kiCadData.firstWhereOrNull((dynamic element) => element.first == 'generator_version') as List<dynamic>?;
    final String? generatorVersion = generatorVersionElement?.elementAt(1) as String?;

    // Get the element in the data containing the layers. This is the first element in the array for which the first
    // element is the string 'layers'.
    final List<dynamic>? layersElement =
        kiCadData.firstWhereOrNull((dynamic element) => element.first == 'layers') as List<dynamic>?;
    // Convert the layers data into a list of KiCadPCBLayer objects.
    final List<KiCadPCBLayer> layers = layersElement
            ?.sublist(1)
            .map((dynamic layerData) => KiCadPCBLayer.fromSExpr(layerData as List<dynamic>))
            .toList() ??
        <KiCadPCBLayer>[];

    // Get a list of modules in the PCB design. This is a list of elements in the array for which the first element
    // is the string 'footprint'. There will typically be multiple 'footprint' elements in the array.
    final List<List<dynamic>> moduleElements =
        kiCadData.whereType<List<dynamic>>().where((List<dynamic> element) => element.first == 'footprint').toList();
    // Convert the module data into a list of KiCadPCBComponent objects.
    final List<KiCadPCBComponent> components = moduleElements.map(KiCadPCBComponent.fromSExpr).toList();

    // Get a list of nets in the PCB design. This is a list of elements in the array for which the first element
    // is the string 'net'. There will typically be multiple 'net' elements in the array.
    final List<List<dynamic>> netElements =
        kiCadData.whereType<List<dynamic>>().where((List<dynamic> element) => element.first == 'net').toList();
    // Convert the net data into a list of KiCadPCBNet objects.
    final List<KiCadPCBNet> nets = netElements.map(KiCadPCBNet.fromSExpr).toList();

    return KiCadPCBDesign(
      version: version,
      generator: generator,
      generatorVersion: generatorVersion,
      layers: layers,
      components: components,
      nets: nets,
    );
  }
}

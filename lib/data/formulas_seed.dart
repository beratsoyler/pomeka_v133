import 'package:flutter/material.dart';

import '../models/formula.dart';
import '../models/formula_category.dart';

const List<FormulaCategory> formulaCategories = [
  FormulaCategory(id: 'kazan', name: 'Kazan', icon: Icons.local_fire_department),
  FormulaCategory(id: 'tesisat', name: 'Tesisat', icon: Icons.plumbing),
  FormulaCategory(id: 'isi', name: 'Isı Transferi', icon: Icons.thermostat),
  FormulaCategory(id: 'pompa', name: 'Pompa', icon: Icons.water),
  FormulaCategory(id: 'boru', name: 'Boru Çapı', icon: Icons.settings_ethernet),
  FormulaCategory(id: 'genlesme', name: 'Genleşme Tankı', icon: Icons.storage),
  FormulaCategory(id: 'baca', name: 'Baca', icon: Icons.cloud),
  FormulaCategory(id: 'enerji', name: 'Enerji', icon: Icons.bolt),
];

const List<Formula> formulasSeed = [
  Formula(
    id: 'kazan_kapasite',
    name: 'Kazan Kapasitesi',
    categoryId: 'kazan',
    categoryName: 'Kazan',
    description: 'Toplam ısı yüküne göre kazan gücü.',
    formulaText: 'QkW = ceil(Qkcal / 860)',
    variables: [
      FormulaVariable(name: 'Qkcal', unit: 'kcal/h'),
    ],
    tags: ['kazan', 'ısı', 'kapasite', 'kW'],
    example: 'Qkcal=97.840 → QkW=114',
  ),
  Formula(
    id: 'kazan_tesisat',
    name: 'Kazan Tesisat Debisi',
    categoryId: 'kazan',
    categoryName: 'Kazan',
    description: 'Zon yüklerine göre debi hesabı.',
    formulaText: 'Q = Yuk / (ΔT * 1000)',
    variables: [
      FormulaVariable(name: 'Yuk', unit: 'kcal/h'),
      FormulaVariable(name: 'ΔT', unit: '°C'),
    ],
    tags: ['kazan', 'debi', 'zon', 'tesisat'],
    example: 'Yuk=27.520, ΔT=10 → Q=2.752 m³/h',
  ),
  Formula(
    id: 'kazan_baca',
    name: 'Kazan Baca Çapı',
    categoryId: 'kazan',
    categoryName: 'Kazan',
    description: 'Yakıt tipine göre baca kesit hesabı.',
    formulaText: 'A = k * Q / √h',
    variables: [
      FormulaVariable(name: 'Q', unit: 'kcal/h'),
      FormulaVariable(name: 'h', unit: 'm'),
    ],
    tags: ['kazan', 'baca', 'çap', 'gaz'],
    example: 'Q=100.000, h=10 → A=... cm²',
  ),
  Formula(
    id: 'tesisat_basinc',
    name: 'Basınç Kayıp',
    categoryId: 'tesisat',
    categoryName: 'Tesisat',
    description: 'Hat basınç kaybı hesabı.',
    formulaText: 'ΔP = f * (L/D) * (ρv²/2)',
    variables: [
      FormulaVariable(name: 'L', unit: 'm'),
      FormulaVariable(name: 'D', unit: 'm'),
      FormulaVariable(name: 'v', unit: 'm/s'),
    ],
    tags: ['basınç', 'kayıp', 'tesisat'],
    example: 'L=50, D=0.05 → ΔP=...',
  ),
  Formula(
    id: 'tesisat_hidrofor',
    name: 'Hidrofor Hesabı',
    categoryId: 'tesisat',
    categoryName: 'Tesisat',
    description: 'Daire sayısına göre debi ve basınç.',
    formulaText: 'Q = n * 4 * tüketim * eşzamanlılık / 1000',
    variables: [
      FormulaVariable(name: 'n', unit: 'adet'),
    ],
    tags: ['hidrofor', 'debi', 'basınç'],
    example: 'n=20 → Q≈...',
  ),
  Formula(
    id: 'isi_kayip',
    name: 'Isı Kaybı',
    categoryId: 'isi',
    categoryName: 'Isı Transferi',
    description: 'Bina ısı kaybı hesabı.',
    formulaText: 'Q = U * A * ΔT',
    variables: [
      FormulaVariable(name: 'U', unit: 'W/m²K'),
      FormulaVariable(name: 'A', unit: 'm²'),
      FormulaVariable(name: 'ΔT', unit: '°C'),
    ],
    tags: ['ısı', 'kayıp', 'bina'],
    example: 'U=0.6, A=100, ΔT=20 → Q=1.200 W',
  ),
  Formula(
    id: 'isi_rekuperator',
    name: 'Reküperatör Verimi',
    categoryId: 'isi',
    categoryName: 'Isı Transferi',
    description: 'Isı geri kazanım verimi.',
    formulaText: 'η = (Tçıkış - Tgiriş) / (Tkapı - Tgiriş)',
    variables: [
      FormulaVariable(name: 'Tçıkış', unit: '°C'),
      FormulaVariable(name: 'Tgiriş', unit: '°C'),
      FormulaVariable(name: 'Tkapı', unit: '°C'),
    ],
    tags: ['verim', 'ısı', 'reküperatör'],
    example: 'Tçıkış=18 → η=...',
  ),
  Formula(
    id: 'pompa_guc',
    name: 'Pompa Gücü',
    categoryId: 'pompa',
    categoryName: 'Pompa',
    description: 'Hidrolik güce göre motor gücü.',
    formulaText: 'P = (ρ * g * Q * H) / η',
    variables: [
      FormulaVariable(name: 'Q', unit: 'm³/s'),
      FormulaVariable(name: 'H', unit: 'm'),
      FormulaVariable(name: 'η', unit: '-'),
    ],
    tags: ['pompa', 'güç', 'verim'],
    example: 'Q=0.02, H=30, η=0.7 → P=...',
  ),
  Formula(
    id: 'pompa_npsh',
    name: 'NPSH Hesabı',
    categoryId: 'pompa',
    categoryName: 'Pompa',
    description: 'Kavitasyon kontrolü için NPSH.',
    formulaText: 'NPSH = (Pa/ρg) + (Vs/2g) - (Pv/ρg)',
    variables: [
      FormulaVariable(name: 'Pa', unit: 'Pa'),
      FormulaVariable(name: 'Pv', unit: 'Pa'),
    ],
    tags: ['pompa', 'npsh', 'kavitasyon'],
    example: 'Pa=... → NPSH=...',
  ),
  Formula(
    id: 'boru_cap_su',
    name: 'Boru Çapı (Su)',
    categoryId: 'boru',
    categoryName: 'Boru Çapı',
    description: 'Debi ve hızdan boru çapı.',
    formulaText: 'D = √(4Q / (π v))',
    variables: [
      FormulaVariable(name: 'Q', unit: 'm³/s'),
      FormulaVariable(name: 'v', unit: 'm/s'),
    ],
    tags: ['boru', 'çap', 'debi', 'hız'],
    example: 'Q=0.01, v=1 → D=0.113 m',
  ),
  Formula(
    id: 'boru_hiz',
    name: 'Boru Hızı',
    categoryId: 'boru',
    categoryName: 'Boru Çapı',
    description: 'Debi ve çapla hız hesabı.',
    formulaText: 'v = 4Q / (π D²)',
    variables: [
      FormulaVariable(name: 'Q', unit: 'm³/s'),
      FormulaVariable(name: 'D', unit: 'm'),
    ],
    tags: ['boru', 'hız', 'debi'],
    example: 'Q=0.01, D=0.1 → v=1.27',
  ),
  Formula(
    id: 'genlesme_acik',
    name: 'Açık Genleşme Tankı',
    categoryId: 'genlesme',
    categoryName: 'Genleşme Tankı',
    description: 'Kazan gücüne göre açık tank hacmi.',
    formulaText: 'Tablo/IF ile kW değerine göre',
    variables: [
      FormulaVariable(name: 'QkW', unit: 'kW'),
    ],
    tags: ['genleşme', 'tank', 'kazan'],
    example: 'QkW=114 → 50 L',
  ),
  Formula(
    id: 'genlesme_kapali',
    name: 'Kapalı Genleşme Tankı',
    categoryId: 'genlesme',
    categoryName: 'Genleşme Tankı',
    description: 'Sistem hacminden kapalı tank.',
    formulaText: 'V = (Ve + Vr) * (Pem+1) / (Pem-Pstat)',
    variables: [
      FormulaVariable(name: 'Ve', unit: 'L'),
      FormulaVariable(name: 'Vr', unit: 'L'),
    ],
    tags: ['genleşme', 'tank', 'basınç'],
    example: 'Ve=40, Vr=5 → V=...',
  ),
  Formula(
    id: 'baca_kesit',
    name: 'Baca Kesit',
    categoryId: 'baca',
    categoryName: 'Baca',
    description: 'Yakıt tipine göre baca kesiti.',
    formulaText: 'A = k * Q / √h',
    variables: [
      FormulaVariable(name: 'Q', unit: 'kcal/h'),
      FormulaVariable(name: 'h', unit: 'm'),
    ],
    tags: ['baca', 'kesit', 'gaz'],
    example: 'Q=80.000, h=12 → A=...',
  ),
  Formula(
    id: 'baca_cekis',
    name: 'Baca Çekişi',
    categoryId: 'baca',
    categoryName: 'Baca',
    description: 'Çekiş kuvveti hesabı.',
    formulaText: 'ΔP = 353 * h * (1/Ta - 1/Tg)',
    variables: [
      FormulaVariable(name: 'h', unit: 'm'),
      FormulaVariable(name: 'Ta', unit: 'K'),
      FormulaVariable(name: 'Tg', unit: 'K'),
    ],
    tags: ['baca', 'çekiş', 'basınç'],
    example: 'h=10 → ΔP=...',
  ),
  Formula(
    id: 'enerji_verim',
    name: 'Sistem Verimi',
    categoryId: 'enerji',
    categoryName: 'Enerji',
    description: 'Verim ve kayıp oranları.',
    formulaText: 'η = Çıkış / Giriş',
    variables: [
      FormulaVariable(name: 'Çıkış', unit: '-'),
      FormulaVariable(name: 'Giriş', unit: '-'),
    ],
    tags: ['verim', 'enerji', 'kayıp'],
    example: 'Çıkış=85, Giriş=100 → η=0.85',
  ),
  Formula(
    id: 'enerji_yakit',
    name: 'Yakıt Tüketimi',
    categoryId: 'enerji',
    categoryName: 'Enerji',
    description: 'Yakıt tüketimi hesabı.',
    formulaText: 'Tüketim = Q / (Alt Isıl Değer)',
    variables: [
      FormulaVariable(name: 'Q', unit: 'kWh'),
    ],
    tags: ['yakıt', 'enerji', 'tüketim'],
    example: 'Q=500 → tüketim=...',
  ),
];

FormulaCategory? categoryById(String id) {
  for (final category in formulaCategories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}

int categoryFormulaCount(String categoryId) {
  return formulasSeed.where((formula) => formula.categoryId == categoryId).length;
}

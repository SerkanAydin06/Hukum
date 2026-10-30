extends RefCounted
class_name MacKaydi

# Tek oyunculu maç kaydı. Dosya yalnızca bu cihazdadır; çok oyunculu maçlar
# kaydedilmez (kopan oyuncu "Maça Dön" ile döner).

const DOSYA := "user://tek_oyunculu_kayit.cfg"
const SURUM := 1

static func kaydet(veri: Dictionary) -> bool:
	var dosya = ConfigFile.new()
	dosya.set_value("kayit", "surum", SURUM)
	dosya.set_value("kayit", "zaman", Time.get_datetime_string_from_system(false, true))
	dosya.set_value("kayit", "veri", veri)
	return dosya.save(DOSYA) == OK

static func yukle() -> Dictionary:
	var dosya = ConfigFile.new()
	if dosya.load(DOSYA) != OK or int(dosya.get_value("kayit", "surum", 0)) != SURUM: return {}
	var veri = dosya.get_value("kayit", "veri", {})
	if typeof(veri) != TYPE_DICTIONARY or typeof(veri.get("oyuncular")) != TYPE_ARRAY or veri["oyuncular"].is_empty(): return {}
	return veri

static func var_mi() -> bool:
	return not yukle().is_empty()

static func ozet() -> String:
	var dosya = ConfigFile.new()
	if dosya.load(DOSYA) != OK: return ""
	var veri = yukle()
	if veri.is_empty(): return ""
	var rakip = veri.get("yapay_zeka", []).size()
	var zaman = str(dosya.get_value("kayit", "zaman", "")).replace("T", " ").left(16)
	return "Tur %d · %s · %s" % [int(veri.get("tur_sayaci", 1)), ("%d rakip" % rakip) if rakip > 0 else "rakipsiz", zaman]

static func sil():
	if FileAccess.file_exists(DOSYA): DirAccess.remove_absolute(ProjectSettings.globalize_path(DOSYA))

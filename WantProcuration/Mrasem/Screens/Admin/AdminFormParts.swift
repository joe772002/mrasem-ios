//
//  AdminFormParts.swift
//  Mrasem
//
//  Phase 14 — أجزاء مشتركة لنماذج الأدمن: إطار النموذج (حفظ / إلغاء / حذف بتأكيد)، واختيارات من قوائم، ومفتاح تشغيل.
//

import SwiftUI

/// اختيار سجل من قائمة (أول عنصر «بدون»).
struct IdSelect: View {
    let label: String
    let options: [PickerOption]
    @Binding var selection: String?

    var body: some View {
        MrasemSelect(
            options: options.map(\.label),
            selectedIndex: Binding(
                get: { options.firstIndex { $0.id == selection } ?? 0 },
                set: { if options.indices.contains($0) { selection = options[$0].id } }
            ),
            label: label
        )
    }
}

/// اختيار قيمة من enum.
struct ValueSelect<Value: Hashable>: View {
    let label: String
    let values: [Value]
    let title: (Value) -> String
    @Binding var selection: Value

    var body: some View {
        MrasemSelect(
            options: values.map(title),
            selectedIndex: Binding(
                get: { values.firstIndex(of: selection) ?? 0 },
                set: { if values.indices.contains($0) { selection = values[$0] } }
            ),
            label: label
        )
    }
}

struct AdminToggleRow: View {
    @Environment(\.mrasem) private var theme

    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .mrasemText(theme.type.body)
                .foregroundColor(theme.colors.ink)
        }
        .tint(theme.colors.maroon)
        .frame(minHeight: theme.dimens.minTouch)
    }
}

/// زر الحذف في النموذج: عنوان ورسالة التأكيد، والفعل.
struct AdminFormDelete {
    let titleKey: String
    let messageKey: String
    let action: () -> Void
}

/// إطار النموذج: عنوان + محتوى + رسالة خطأ + حفظ / إلغاء + حذف اختياري بتأكيد (G3).
/// `onSave` بيرجّع مفتاح رسالة الخطأ، أو `nil` لو اتحفظ (النموذج بيتقفل).
struct AdminFormSheet<Content: View>: View {
    @Environment(\.mrasem) private var theme
    @Environment(\.dismiss) private var dismiss

    let titleKey: String
    let onSave: () -> String?
    let delete: AdminFormDelete?
    @ViewBuilder var content: () -> Content

    @State private var errorKey: String?
    @State private var confirmDelete = false

    var body: some View {
        let c = theme.colors

        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                Text(mrasemString(titleKey))
                    .mrasemText(theme.type.cardTitle)
                    .foregroundColor(c.maroon)
                    .accessibilityAddTraits(.isHeader)

                content()

                if let errorKey {
                    Text(mrasemString(errorKey))
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(c.warn)
                        .accessibilityLabel(mrasemString(errorKey))
                }

                MrasemButton(mrasemString("mrasem_admin_form_save"), variant: .primary, block: true) {
                    errorKey = onSave()
                    if errorKey == nil { dismiss() }
                }
                MrasemButton(mrasemString("mrasem_admin_form_cancel"), variant: .ghost, block: true) { dismiss() }

                if delete != nil {
                    MrasemButton(mrasemString("mrasem_admin_form_delete"), variant: .outline, block: true) {
                        confirmDelete = true
                    }
                }
            }
            .padding(theme.dimens.screenHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(c.bg.ignoresSafeArea())
        .alert(mrasemString(delete?.titleKey ?? ""), isPresented: $confirmDelete) {
            Button(mrasemString("mrasem_admin_form_delete"), role: .destructive) {
                delete?.action()
                dismiss()
            }
            Button(mrasemString("mrasem_admin_form_cancel"), role: .cancel) {}
        } message: {
            Text(mrasemString(delete?.messageKey ?? ""))
        }
    }
}

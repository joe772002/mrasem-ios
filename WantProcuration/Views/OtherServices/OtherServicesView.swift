import SwiftUI
import SwiftfulRouting

// MARK: - Service Model
struct WebService: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let url: String
    let color: Color
}

// MARK: - Other Services Screen
struct OtherServicesView: View {
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    
    let services: [WebService] = [
        WebService(
            title: "خدمات الترجمه",
            description: "الوصول إلى الخدمات الحكومية",
            icon: "globe.desk",
            url: "https://rern.gov.eg/",
            color: .blue
        ),
        WebService(
            title: "شهادات عقارية",
            description: "الوصول إلى الخدمات الحكومية",
            icon: "doc.text.magnifyingglass",
            url: "https://rern.gov.eg/",
            color: .green
        ),
        WebService(
            title: "صوره من عقد مشهر",
            description: "الوصول إلى الخدمات الحكومية",
            icon: "doc.on.doc",
            url: "https://rern.gov.eg/",
            color: .orange
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 50))
                        .foregroundColor(.theme.themeBlue)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.theme.themeBlue.opacity(0.1))
                        )
                    
                    Text("خدمات أخرى")
                        .font(.setFontSemiBold(size: 20))
                        .foregroundColor(.theme.text)
                    
                    Text("المزيد من الخدمات")
                        .font(.setFont())
                        .foregroundColor(.theme.secondaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Services List
                VStack(spacing: 12) {
                    ForEach(services) { service in
                        ServiceCard(appManager: appManager,service: service) {
                            router.showScreen(.push) { _ in
                                WebViewScreen(url: service.url, title: service.title)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }.background(HomeBackground())
            .environment(\.locale, appManager.locale)
            .environment(\.layoutDirection, appManager.layoutDirection)
    }
}

// MARK: - Service Card Component
struct ServiceCard: View {
    @ObservedObject var appManager: AppManager
    let service: WebService
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.theme.darkBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: service.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color.theme.darkBlue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.title)
                        .font(.setFontSemiBold(size: 16))
                        .foregroundColor(.theme.text)
                        .multilineTextAlignment(.leading)
                    
                    Text(service.description)
                        .font(.setFontLight())
                        .foregroundColor(.theme.secondaryText2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow
                Image(systemName: appManager.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.theme.secondaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct OtherServicesScreen_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simple mock AppManager to avoid heavy initialization
        let appManager = AppManager()
        
        // Use a NavigationView wrapper for better preview
        
        OtherServicesView(appManager: appManager)
    }
}

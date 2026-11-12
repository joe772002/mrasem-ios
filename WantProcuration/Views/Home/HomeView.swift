import SwiftUI
import SwiftfulRouting
import SwiftfulUI

// MARK: - Home Screen View
struct HomeScreenView: View {
   
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            HomeBackground()
            
//            Color.theme.background
//                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HomeHeaderView(appManager: appManager)
              
                ScrollView {
                    VStack(spacing: 10) {
                        HomeHeaderCard().padding(.top , 14)   // breathing room under «كيف يمكننا مساعدتك؟»
                        // Services Section
                        // Title sits close to the list it introduces.
                        VStack(alignment: .leading, spacing: 10) {
                            Text("avalibaleServices".localized())
                                .font(.setFontBold(size: 24))
                                .foregroundColor(.theme.text)
                                .padding(.horizontal , 20)
                                .padding(.top , 2)    // close to the card above; same rhythm as the list below
                            
                            // Grid
                           VStack(spacing: 16) {
                                ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                                    if index % 2 == 0 {
                                        VStack(spacing: 16) {
                                            HorizontalServiceCard(
                                                appManager: appManager, category: viewModel.categories[index],
                                                index: index
                                            ) {
                                                showSelectedView(viewModel.categories[index])
                                                // FIX: Use closure for tap action
                                                
                                            }
                                            
                                            if index + 1 < viewModel.categories.count {
                                                HorizontalServiceCard(
                                                    appManager: appManager, category: viewModel.categories[index + 1],
                                                    index: index + 1
                                                ) {
                                                    // FIX: Use closure for tap action
                                                   showSelectedView(viewModel.categories[index + 1])
                                                }
                                            } else {
                                                Spacer()
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Room so the floating assistant button doesn't cover the last card.
                        Color.clear.frame(height: 96)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            AssistantFloatingButton {
                openAssistant()
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
        .preferredColorScheme(appManager.isDarkMode ? .dark : .light)
    }

    /// The assistant opens as a sheet over Home (its own navigation, so booking can continue inside it).
    private func openAssistant() {
        router.showScreen(.sheet) { _ in
            AssistantView(appManager: appManager, showsCloseButton: true)
        }
    }
    
    func showSelectedView(_ category: ServiceCategory){
        switch category.categoryName {
        case .capacity:
            router.showScreen(.push) { _ in
                OfficeListView(appManager: appManager , category: category.categoryName)
            }
        case .reserve:
            router.showScreen(.push) { _ in
                return  OfficeListView(appManager: appManager , category: category.categoryName)
            }
        case .templates:
            
            router.showScreen(.push) { _ in
                return  WebViewScreen(url: "https://rern.gov.eg/pages/requests/2", title: category.categoryName.title )
            }
            break
        case .inquire:
            router.showScreen(.push) { _ in
                return  ReservationInquiryView(appManager: appManager)
            }
        case .electronicTawseek:
            
            router.showScreen(.push) { _ in
                return  WebViewScreen(url: "https://digital.gov.eg/" , title: category.categoryName.title)
            }
            break
        case .others:
            
            router.showScreen(.push) { _ in
                return  OtherServicesView(appManager: appManager)
            }
            break
        case .assistant:
            router.showScreen(.push) { _ in
                AssistantView(appManager: appManager)
            }
        case .faq:
            router.showScreen(.push) { _ in
                FAQView(appManager: appManager)
            }
        }
    }
}




// MARK: - Preview
struct HomeScreenView_Previews: PreviewProvider {
  
    static var previews: some View {
        let appManager = AppManager()
        RouterView { _ in
            HomeScreenView(appManager:appManager )
                .environment(\.locale, appManager.locale)
                .environment(\.layoutDirection, appManager.layoutDirection)
                .preferredColorScheme(.dark)
        }
    }
}

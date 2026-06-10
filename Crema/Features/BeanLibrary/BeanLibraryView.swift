//
//  BeanLibraryView.swift
//  Crema
//

import SwiftUI

// MARK: - ViewModel

@Observable @MainActor
final class BeanLibraryViewModel {
    var beans: [Bean] = []
    var isLoading = false
    var error: String?

    private let repo: BeanRepositoryProtocol

    init(repo: BeanRepositoryProtocol = BeanRepository()) {
        self.repo = repo
    }

    func load() async {
        isLoading = true
        error = nil
        do { beans = try await repo.fetchBeans() }
        catch APIError.unauthenticated { /* sign-out in progress, ContentView routes to AuthView */ }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func add(_ payload: CreateBeanPayload) async throws -> Bean {
        let bean = try await repo.createBean(payload)
        beans.insert(bean, at: 0)
        return bean
    }

    func delete(_ bean: Bean) async {
        do {
            try await repo.deleteBean(id: bean.id)
            beans.removeAll { $0.id == bean.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - View

struct BeanLibraryView: View {
    @State private var viewModel = BeanLibraryViewModel()
    @State private var searchText = ""
    @State private var showAddBean = false
    @State private var logShotBean: Bean?
    @State private var showLogShot = false

    private var filtered: [Bean] {
        guard !searchText.isEmpty else { return viewModel.beans }
        return viewModel.beans.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.roaster?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                CremaDivider()
                content
            }

            fab
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Bean.self) { bean in
            BeanDetailView(bean: bean, onLogShot: { b in
                logShotBean = b
                showLogShot = true
            })
        }
        .sheet(isPresented: $showAddBean) {
            AddBeanView { payload in
                Task { _ = try? await viewModel.add(payload) }
            }
        }
        .fullScreenCover(isPresented: $showLogShot) {
            LogShotView(initialBean: logShotBean) {
                showLogShot = false
            }
        }
        .task { await viewModel.load() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: Sub-views

    private var header: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("My Beans")
                    .font(.cremaDisplay(size: 28))
                    .foregroundStyle(Color.cremaTextPrimary)
                Spacer()
                Text("\(viewModel.beans.count) total")
                    .font(.cremaMono(size: 9))
                    .tracking(0.08 * 9)
                    .foregroundStyle(Color.cremaTextSecondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.cremaTextSecondary)
                TextField("search beans…", text: $searchText)
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextPrimary)
                    .tint(Color.cremaCopper)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.cremaTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cremaInputBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cremaBorder, lineWidth: 0.5))
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.beans.isEmpty {
            Spacer()
            ProgressView().tint(Color.cremaCopper)
            Spacer()
        } else if filtered.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, bean in
                        HStack(alignment: .top, spacing: 12) {
                            // Left: NavigationLink covers only the bean info area
                            NavigationLink(value: bean) {
                                BeanRowContent(bean: bean)
                            }
                            .buttonStyle(.plain)

                            // Right: log button stays independent
                            Button {
                                logShotBean = bean
                                showLogShot = true
                            } label: {
                                Text("+ log")
                                    .font(.cremaBody(size: 11, weight: .medium))
                                    .foregroundStyle(Color.cremaBgPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.cremaCopper)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 16)
                            .padding(.trailing, 24)
                        }

                        if idx < filtered.count - 1 {
                            CremaDivider(inset: 24)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await viewModel.load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(searchText.isEmpty ? "No beans yet." : "No results.")
                .font(.cremaBody(size: 14))
                .foregroundStyle(Color.cremaTextSecondary)
            if searchText.isEmpty {
                Text("Tap + to add your first bean.")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary.opacity(0.6))
            }
            Spacer()
        }
    }

    private var fab: some View {
        Button { showAddBean = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.cremaBgPrimary)
                .frame(width: 52, height: 52)
                .background(Color.cremaCopper)
                .clipShape(Circle())
                .shadow(color: Color.cremaCopper.opacity(0.45), radius: 12, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Bean row content (NavigationLink label)

private struct BeanRowContent: View {
    let bean: Bean

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bean.name)
                    .font(.cremaBody(size: 15, weight: .medium))
                    .foregroundStyle(Color.cremaTextPrimary)
                if let roaster = bean.roaster {
                    Text(roaster)
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaTextSecondary)
                }
            }
            HStack(spacing: 6) {
                if let origin = bean.origin { CremaPillTag(label: origin) }
                if let process = bean.process { CremaPillTag(label: process.displayName) }
                if let roastLevel = bean.roastLevel { CremaPillTag(label: roastLevel.displayName) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 24)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack { BeanLibraryView() }
}

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
        Group {
            if viewModel.isLoading && viewModel.beans.isEmpty {
                ProgressView().tint(Color.cremaCopper)
            } else if filtered.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Beans Yet",
                        systemImage: "bag",
                        description: Text("Tap + to add your first bean.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(filtered) { bean in
                        HStack(alignment: .top) {
                            BeanRowContent(bean: bean)
                            Button {
                                logShotBean = bean
                                showLogShot = true
                            } label: {
                                Text("+ log")
                                    .font(.cremaBody(size: 13, weight: .medium))
                                    .foregroundStyle(Color.cremaBgPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.cremaCopper)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 16)
                            .padding(.trailing, 4)
                        }
                        .background(
                            NavigationLink(value: bean) { EmptyView() }
                                .opacity(0)
                        )
                        .listRowBackground(Color.cremaBgPrimary)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                        .listRowSeparatorTint(Color.cremaBorder)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(bean) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                logShotBean = bean
                                showLogShot = true
                            } label: {
                                Label("Log Shot", systemImage: "cup.and.saucer.fill")
                            }
                            .tint(Color.cremaCopper)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load() }
            }
        }
        .background(Color.cremaBgPrimary.ignoresSafeArea())
        .navigationTitle("My Beans")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search beans…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddBean = true } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
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
        .sheet(isPresented: $showLogShot) {
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
}

// MARK: - Bean row content

private struct BeanRowContent: View {
    let bean: Bean

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bean.name)
                    .font(.cremaBody(size: 17, weight: .medium))
                    .foregroundStyle(Color.cremaTextPrimary)
                if let roaster = bean.roaster {
                    Text(roaster)
                        .font(.cremaBody(size: 14))
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
        .padding(.leading, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationStack { BeanLibraryView() }
}

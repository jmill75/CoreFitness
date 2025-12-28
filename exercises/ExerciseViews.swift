import SwiftUI

// MARK: - Exercise Browse View (Main Category Grid)
/// Matches your "Browse by Category" screen with colorful category cards
struct ExerciseBrowseView: View {
    @StateObject private var exerciseService = ExerciseService()
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Grid
                    Text("Browse by Category")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(ExerciseCategory.allCases) { category in
                            NavigationLink(destination: ExerciseListView(
                                category: category,
                                exercises: exerciseService.exercises(for: category)
                            )) {
                                CategoryCard(
                                    category: category,
                                    count: exerciseService.count(for: category)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Filters Section
                    Text("Quick Filters")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search exercises", text: $searchText)
                            .foregroundColor(.white)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Difficulty Filter Button
                        Menu {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Button(difficulty.rawValue) {
                                    // Handle filter
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Difficulty")
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.2))
                    .cornerRadius(20)
                }
            }
            .task {
                await exerciseService.loadFromBundle()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Category Card
/// Colorful category card matching your UI design
struct CategoryCard: View {
    let category: ExerciseCategory
    let count: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background color
            Color(hex: category.color)
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    // Count badge
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Category name
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(height: 120)
    }
}

// MARK: - Exercise List View
/// List of exercises in a category, matching your filtered view
struct ExerciseListView: View {
    let category: ExerciseCategory
    let exercises: [Exercise]
    
    @State private var favoriteExercises: Set<String> = []
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter chip
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: category.iconName)
                        .foregroundColor(Color(hex: category.color))
                    Text(category.rawValue)
                        .foregroundColor(Color(hex: category.color))
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: category.color))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: category.color).opacity(0.2))
                .cornerRadius(20)
                
                Spacer()
            }
            .padding()
            
            // Exercise count and clear button
            HStack {
                Text("\(filteredExercises.count) exercises")
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("Clear All") {
                    // Clear filters
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // Exercise list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredExercises) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            ExerciseRowView(
                                exercise: exercise,
                                isFavorite: favoriteExercises.contains(exercise.id),
                                onFavoriteToggle: {
                                    toggleFavorite(exercise.id)
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            
            // Search bar at bottom
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search exercises", text: $searchText)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(12)
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleFavorite(_ id: String) {
        if favoriteExercises.contains(id) {
            favoriteExercises.remove(id)
        } else {
            favoriteExercises.insert(id)
        }
    }
}

// MARK: - Exercise Row View
/// Single exercise row matching your list design
struct ExerciseRowView: View {
    let exercise: Exercise
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise icon
            ZStack {
                Circle()
                    .fill(Color(hex: exercise.category.color).opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: exercise.category.iconName)
                    .font(.title3)
                    .foregroundColor(Color(hex: exercise.category.color))
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    // Difficulty badge
                    Text(exercise.difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    
                    // Equipment
                    Text(exercise.equipment.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Favorite button
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
                    .font(.title3)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Detail View
/// Detailed exercise view with GIF/video and instructions
struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var isFavorite = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Exercise GIF/Video
                AsyncImage(url: URL(string: exercise.gifUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(height: 300)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(16)
                
                // Exercise name and info
                VStack(alignment: .leading, spacing: 12) {
                    Text(exercise.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Tags
                    HStack(spacing: 8) {
                        TagView(text: exercise.difficulty.rawValue, color: Color(hex: exercise.difficulty.color))
                        TagView(text: exercise.equipment.displayName, color: .blue)
                        TagView(text: exercise.bodyPart.displayName, color: .purple)
                    }
                }
                
                // Target muscles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Muscles")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(exercise.target.capitalized)
                        .foregroundColor(.green)
                        .font(.subheadline)
                    
                    if !exercise.secondaryMuscles.isEmpty {
                        Text("Secondary: \(exercise.secondaryMuscles.joined(separator: ", "))")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(white: 0.12))
                .cornerRadius(12)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(hex: exercise.category.color))
                                .clipShape(Circle())
                            
                            Text(instruction)
                                .foregroundColor(.white.opacity(0.9))
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.12))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                }
            }
        }
    }
}

// MARK: - Tag View
struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .cornerRadius(6)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Provider
#Preview {
    ExerciseBrowseView()
}

import SwiftUI

// 1. Modellen som matchar vad din FastAPI-backend skickar tillbaka
struct TodoItem: Codable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
}

struct ContentView: View {
    // State-variabler som håller koll på appens data
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Rubrik
            Text("Todos")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            // Inmatningsfält och knapp för att lägga till
            HStack {
                TextField("Skriv en ny todo...", text: $newTodoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))

                Button(action: {
                    addTodo()
                }) {
                    Text("Lägg till")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                // Inaktivera knappen om fältet är tomt
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            // Felmeddelande om anropet misslyckas
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Listan som visar alla todos
            List(todos) { todo in
                HStack {
                    Text(todo.title)
                        .strikethrough(todo.completed, color: .gray)
                        .foregroundColor(todo.completed ? .gray : .primary)
                    
                    Spacer()
                    
                    // Ikon som visar om den är klar eller ej
                    Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(todo.completed ? .green : .gray)
                        .font(.title3)
                }
                .padding(.vertical, 4)
            }
            .listStyle(InsetListStyle())
        }
        .frame(minWidth: 350, minHeight: 450)
        .padding()
        // När appen startar hämtar vi todos från backenden
        .onAppear {
            fetchTodos()
        }
    }

    // MARK: - API Anrop (Network Functions)

    // 1. Hämta alla todos (GET /todos)
    func fetchTodos() {
        guard let url = URL(string: "http://127.0.0.1:8000/todos") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Kunde inte nå servern: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else { return }

            do {
                let decodedResponse = try JSONDecoder().decode([TodoItem].self, from: data)
                DispatchQueue.main.async {
                    self.todos = decodedResponse
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Kunde inte avkoda data från servern."
                }
            }
        }.resume()
    }

    // 2. Skapa en ny todo (POST /todos)
    func addTodo() {
        guard let url = URL(string: "http://127.0.0.1:8000/todos") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["title": newTodoTitle]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Kunde inte skapa todo: $error.localizedDescription$"
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    self.newTodoTitle = "" // Töm fältet
                    self.fetchTodos()     // Uppdatera listan direkt
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Servern svarade med felkod."
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}

# 💰 App de Controle de Gastos (Flutter)

Aplicativo mobile para registrar **receitas e despesas por categoria**, ver o **saldo do mês** e um **gráfico de pizza** dos gastos. Os dados ficam salvos no próprio celular.

## ✨ Funcionalidades
- Adicionar receita ou despesa (descrição, valor, categoria)
- Saldo, total de receitas e total de despesas
- Gráfico de pizza das despesas por categoria
- Arrastar para o lado para excluir um lançamento
- Persistência local com `shared_preferences`

## 🧰 Tecnologias
- Flutter 3 / Dart
- `fl_chart` (gráficos)
- `shared_preferences` (armazenamento local)
- `intl` (formatação em R$)

## 🚀 Como rodar
```bash
# pré-requisito: Flutter instalado (https://docs.flutter.dev/get-started/install)
git clone https://github.com/MoniqueSilva79/expense-tracker-app.git
cd expense-tracker-app
flutter create .        # gera as pastas android/ e ios/ sem sobrescrever lib/
flutter pub get
flutter run
```

## 📁 Estrutura
```
lib/
└── main.dart   # modelo, persistência e telas
```

## 📚 O que pratiquei
- Widgets e gerenciamento de estado com `StatefulWidget`
- Persistência local em JSON
- Gráficos no mobile

## 🗺️ Próximos passos
- [ ] Filtro por mês
- [ ] Banco SQLite (`sqflite`) e exportação para CSV
- [ ] Sincronização com Firebase

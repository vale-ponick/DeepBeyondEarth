//
//  readmeBaseCampLogistics.md
//  DeepBeyondEarth
//
//  Created by Валерия Пономарева on 18.11.2026.
//

import Foundation
 
ТТЗ №1: Склад снабжения лунной базы (ArtemisBaseCamp)
Отрабатываемые связки
5️⃣ Code Structuring (mutating, extension, инкапсуляция состояния)

6️⃣ Errors & Handling (enum Error, throws, do-catch)

9️⃣ Clean Code (защита свойств через private(set), разделение логики и вывода)

1. Легенда миссии
На Южном полюсе Луны разворачивается модуль снабжения базового лагеря «Артемида». Грузовой шлюз принимает герметичные контейнеры с ресурсами (вода, кислород, научное оборудование) и выдает их экипажу. Из-за жёстких ограничений по массе и объёму складской отсек имеет строгий лимит вместимости, а бортовой компьютер блокирует любые некорректные операции приёмки и выдачи.

2. Архитектурные требования
А. Перечисление ошибок LogisticsError: LocalizedError — ровно 5 кейсов
#    Кейс    Когда возникает
1    emptyName    имя после trim — пустая строка
2    invalidAmount(amount: Int)    количество <= 0
3    capacityExceeded(available: Int, requested: Int)    загрузка + amount > maxCapacity
4    resourceNotFound(name: String)    при dispatch ключа нет в словаре
5    insufficientStock(available: Int, requested: Int)    при dispatch остаток < amount
errorDescription — для каждого кейса.

Б. Модель склада BaseCampStorage
Свойства:

text
let maxCapacity: Int                 — задаётся при создании, не меняется
private(set) var resources: [String: Int]   — словарь, меняется только внутри
private(set) — только на resources. maxCapacity — let, private(set) не нужен.

Computed properties:

text
var currentLoad: Int         — сумма всех значений словаря
var freeSpace: Int           — maxCapacity - currentLoad
var isFull: Bool             — freeSpace == 0
В. Методы управления (mutating + throws)
receive(name: String, amount: Int) throws:

let key = name.trimmingCharacters(in: .whitespaces) — trim до проверки;

guard !key.isEmpty → throw .emptyName;

guard amount > 0 → throw .invalidAmount(amount:);

guard currentLoad + amount <= maxCapacity → throw .capacityExceeded(available: freeSpace, requested: amount);

resources[key, default: 0] += amount — в словарь идёт key (trimmed).

dispatch(name: String, amount: Int) throws:

let key = name.trimmingCharacters(in: .whitespaces);

guard !key.isEmpty → throw .emptyName;

guard amount > 0 → throw .invalidAmount(amount:);

guard let stock = resources[key] → throw .resourceNotFound(name: key);

guard stock >= amount → throw .insufficientStock(available: stock, requested: amount);

if stock == amount { resources.removeValue(forKey: key) } else { resources[key] = stock - amount } — ключ удаляется при нуле.

print() внутри модели запрещён — только throw или изменение состояния.

Г. Расширение extension BaseCampStorage
func report() -> String — формат фиксирован:

text
"Storage: 120/500, free: 380, items: RTG(2), Food(10), Water(5)"
если словарь пуст: "Storage: 0/500, free: 500, items: —";

позиции — через ,, в формате name(count).

3. План работы
Псевдокод — выполнен (см. раздел 4 ниже). Отдельно писать не нужно.

baseCampLogistics.swift — реализация LogisticsError и BaseCampStorage полностью самостоятельно.

testsBaseCampLogistics.swift — проверки всех позитивных и негативных сценариев.

4. Алгоритмы (IPO) — для справки
receive (Вход → Барьеры → Изменение состояния)
text
Вход: name, amount
Барьер 1: trim(name) → key; key не пуст?
Барьер 2: amount > 0?
Барьер 3: currentLoad + amount <= maxCapacity?
Действие: resources[key, default: 0] += amount
dispatch
text
Вход: name, amount
Барьер 1: trim(name) → key; key не пуст?
Барьер 2: amount > 0?
Барьер 3: resources[key] существует?
Барьер 4: resources[key] >= amount?
Действие:
  если stock == amount → resources.removeValue(forKey: key)
  иначе → resources[key] = stock - amount
5. Чек-лист тестов (testsBaseCampLogistics.swift)
Позитивные:

Успешная приёмка — новый ресурс + пополнение существующего.

Частичная выдача — остаток уменьшается, ключ остаётся.

Полная выдача под ноль — ключ удаляется из словаря.

Негативные — по одному do/catch на каждый кейс:

Кейс    Что проверить
emptyName    receive(name: " ", amount: 10) и dispatch
invalidAmount    amount: 0 и amount: -5
capacityExceeded    currentLoad + amount > maxCapacity
resourceNotFound    dispatch несуществующего ключа
insufficientStock    dispatch больше, чем есть
Дополнительно: trim — receive(name: " RTG ", amount: 2), затем dispatch(name: "RTG", amount: 1) — должен найти тот же ключ.

Изменения по сравнению с исходным ТЗ
5 кейсов зафиксированы явно — раньше было 4 пункта, но третий и четвёртый — по два кейса.

maxCapacity — let, private(set) — только на resources.

Trim до проверки; в словарь идёт trimmed имя.

Формат report() задан примером.

Псевдокод помечен как выполненный — не дублируется.


Что важно учесть, чтобы не потерять самостоятельность

Поскольку в этой версии внутри пункта 2.В уже прописаны конкретные строчки синтаксиса Swift (а не только логика), при переносе в baseCampLogistics.swift используй их как контрольный чек-лист, а не как текст для слепого копирования:
• Сначала сверяйся со схемой IPO (раздел 4). Пиши код в Xcode, глядя на логику барьеров из раздела 4, и только если застрянешь в синтаксисе — подсматривай в раздел 2.
• Обрати внимание на инициатор (инициализатор) структуры. В BaseCampStorage свойство resources имеет модификатор private(set). Чтобы при создании склада тебе не приходилось каждый раз передавать пустой словарь снаружи, задай ему значение по умолчанию прямо при объявлении (private(set) var resources: [String: Int] = [:]). Тогда экземпляр можно будет создать чисто: BaseCampStorage(maxCapacity: 500).
• Учти порядок элементов в report(). В Swift словарь (Dictionary) не гарантирует порядок ключей. Если при формировании строки items: RTG(2), Food(10), Water(5) ты захочешь, чтобы ресурсы в отчете всегда шли в предсказуемом алфавитном порядке (это сильно упрощает автоматическую проверку строки в тестах), отсортируй пары словаря по ключу перед склейкой.

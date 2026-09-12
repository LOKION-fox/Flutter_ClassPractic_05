#!/usr/bin/env node

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');


// ============================================================
// ПАРАМЕТРЫ ЗАПУСКА
// ============================================================

const args = process.argv.slice(2);

function arg(name, fallback) {
  const index = args.indexOf(`--${name}`);

  if (index !== -1 && args[index + 1]) {
    return args[index + 1];
  }

  return fallback;
}

const PORT = Number(
  arg('port', 8080),
);

const ORIGIN = arg(
  'origin',
  'http://localhost:5555',
);

// Секрет используется только внутри учебного сервера.
const SECRET =
  'pet-shop-practice-5-secret';

// Access token по умолчанию живёт 15 минут.
// Для проверки ПР5 можно:
// node mock-server.js --ttl 60
const ACCESS_TTL = Number(
  arg('ttl', 900),
);

// Refresh token живёт 7 дней.
const REFRESH_TTL =
  60 * 60 * 24 * 7;


// ============================================================
// ТОКЕНЫ И ПАРОЛИ
// ============================================================

function b64url(value) {
  return Buffer
    .from(value)
    .toString('base64url');
}

function sign(payload) {
  const body = b64url(
    JSON.stringify({
      ...payload,
      jti: crypto.randomUUID(),
    }),
  );

  const signature = crypto
    .createHmac('sha256', SECRET)
    .update(body)
    .digest('base64url');

  return `${body}.${signature}`;
}

function verify(token) {
  if (
    typeof token !== 'string' ||
    !token.includes('.')
  ) {
    return null;
  }

  const parts = token.split('.');

  if (parts.length !== 2) {
    return null;
  }

  const [body, signature] = parts;

  const expected = crypto
    .createHmac('sha256', SECRET)
    .update(body)
    .digest('base64url');

  if (signature !== expected) {
    return null;
  }

  try {
    const payload = JSON.parse(
      Buffer
        .from(body, 'base64url')
        .toString('utf8'),
    );

    if (
      payload.exp &&
      payload.exp * 1000 <
        Date.now()
    ) {
      return null;
    }

    return payload;
  } catch {
    return null;
  }
}

function hash(password) {
  return crypto
    .createHash('sha256')
    .update(
      `${password}${SECRET}`,
    )
    .digest('hex');
}


// ============================================================
// "БАЗА ДАННЫХ" В ПАМЯТИ
// ============================================================

let db;

function push(
  collection,
  object,
) {
  db.seq[collection] =
    (db.seq[collection] || 0) + 1;

  const id =
    db.seq[collection];

  db[collection].push({
    id,
    ...object,
    createdAt:
      new Date().toISOString(),
    deletedAt: null,
  });

  return id;
}

function seed() {
  db = {
    seq: {},

    products: [],
    animals: [],
    categories: [],
    suppliers: [],
    customers: [],

    users: [],

    refreshTokens:
      new Set(),
  };


  // ==========================================================
  // КАТЕГОРИИ
  // ==========================================================

  const categories = [
    [
      'Корм',
      'product',
      'Корма для домашних животных',
    ],
    [
      'Игрушки',
      'product',
      'Игрушки для животных',
    ],
    [
      'Аксессуары',
      'product',
      'Ошейники, поводки, миски и переноски',
    ],
    [
      'Гигиена',
      'product',
      'Средства ухода и гигиены',
    ],
    [
      'Аквариумистика',
      'product',
      'Товары для аквариумов',
    ],
    [
      'Веттовары',
      'both',
      'Средства для здоровья животных',
    ],
    [
      'Кошки',
      'animal',
      'Кошки различных пород',
    ],
    [
      'Собаки',
      'animal',
      'Собаки различных пород',
    ],
    [
      'Грызуны',
      'animal',
      'Хомяки и другие грызуны',
    ],
    [
      'Птицы',
      'animal',
      'Домашние декоративные птицы',
    ],
    [
      'Кролики',
      'animal',
      'Декоративные кролики',
    ],
    [
      'Морские свинки',
      'animal',
      'Домашние морские свинки',
    ],
    [
      'Террариумистика',
      'product',
      'Товары для террариумов',
    ],
  ];

  for (const item of categories) {
    push(
      'categories',
      {
        name: item[0],
        kind: item[1],
        description: item[2],
      },
    );
  }


  // ==========================================================
  // ПОСТАВЩИКИ
  // ==========================================================

  const suppliers = [
    {
      name: 'ЗооОпт',
      country: 'Россия',
      email: 'opt@zoopt.ru',
      allowedCategoryIds:
        [1, 2, 3, 4, 6],
    },
    {
      name:
        'PetFood Distribution',
      country: 'Россия',
      email: 'food@petfood.ru',
      allowedCategoryIds:
        [1, 6],
    },
    {
      name: 'AquaWorld',
      country: 'Германия',
      email: 'info@aquaworld.de',
      allowedCategoryIds:
        [5],
    },
    {
      name: 'Animal House',
      country: 'Россия',
      email: 'animals@house.ru',
      allowedCategoryIds:
        [7, 8, 9, 11, 12],
    },
    {
      name: 'BirdLand',
      country: 'Польша',
      email: 'birds@birdland.pl',
      allowedCategoryIds:
        [10],
    },
    {
      name: 'PetMarket Север',
      country: 'Россия',
      email: 'north@petmarket.ru',
      allowedCategoryIds: [
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
      ],
    },
    {
      name: 'ВетСнаб',
      country: 'Россия',
      email: 'vet@vetsnab.ru',
      allowedCategoryIds:
        [6],
    },
    {
      name: 'Happy Pets',
      country: 'Беларусь',
      email: 'shop@happypets.by',
      allowedCategoryIds:
        [2, 3, 4, 7, 8],
    },
    {
      name: 'ГрызунОПТ',
      country: 'Россия',
      email: 'rodent@opt.ru',
      allowedCategoryIds:
        [9, 11, 12],
    },
    {
      name: 'Птичий мир',
      country: 'Россия',
      email: 'bird@world.ru',
      allowedCategoryIds:
        [10],
    },
    {
      name: 'Premium Food',
      country: 'Франция',
      email: 'food@premium.fr',
      allowedCategoryIds:
        [1],
    },
    {
      name: 'Terra Zoo',
      country: 'Россия',
      email: 'terra@zoo.ru',
      allowedCategoryIds:
        [13],
    },
  ];

  for (const supplier of suppliers) {
    push(
      'suppliers',
      supplier,
    );
  }


  // ==========================================================
  // ТОВАРЫ
  // ==========================================================

  const products = [
    [
      'Royal Canin Sterilised',
      'RC-001',
      'Royal Canin',
      1890,
      25,
      2,
      [1],
      'Сухой корм для стерилизованных кошек',
    ],
    [
      'Royal Canin Mini Adult',
      'RC-002',
      'Royal Canin',
      2250,
      18,
      2,
      [1],
      'Корм для взрослых собак мелких пород',
    ],
    [
      'Purina One Cat',
      'PU-001',
      'Purina',
      1230,
      31,
      1,
      [1],
      'Сухой корм для взрослых кошек',
    ],
    [
      'Purina Dog Chow',
      'PU-002',
      'Purina',
      1780,
      21,
      1,
      [1],
      'Полнорационный корм для собак',
    ],
    [
      'Brit Premium Cat',
      'BR-001',
      'Brit',
      1460,
      17,
      1,
      [1],
      'Корм для взрослых домашних кошек',
    ],
    [
      "Hill's Science Plan",
      'HI-001',
      "Hill's",
      2490,
      13,
      11,
      [1],
      'Сбалансированный корм для кошек',
    ],
    [
      'Мяч Trixie',
      'TR-001',
      'Trixie',
      450,
      45,
      1,
      [2],
      'Резиновый мяч для собак',
    ],
    [
      'Игрушка-мышь Trixie',
      'TR-002',
      'Trixie',
      320,
      52,
      1,
      [2],
      'Игрушка для кошек',
    ],
    [
      'Канат для собак',
      'TR-003',
      'Trixie',
      680,
      19,
      1,
      [2],
      'Канат для активных собак',
    ],
    [
      'Поводок Flexi Classic',
      'FL-001',
      'Flexi',
      1990,
      14,
      1,
      [3],
      'Рулетка-поводок длиной 5 метров',
    ],
    [
      'Ошейник Trixie',
      'TR-004',
      'Trixie',
      840,
      28,
      1,
      [3],
      'Регулируемый ошейник',
    ],
    [
      'Переноска для кошек',
      'TR-005',
      'Trixie',
      2990,
      9,
      1,
      [3],
      'Пластиковая переноска',
    ],
    [
      'Шампунь Beaphar',
      'BE-001',
      'Beaphar',
      950,
      22,
      1,
      [4],
      'Мягкий шампунь для собак',
    ],
    [
      'Средство для шерсти',
      'BE-002',
      'Beaphar',
      1130,
      16,
      1,
      [4],
      'Средство ухода за шерстью',
    ],
    [
      'Щётка Trixie',
      'TR-006',
      'Trixie',
      790,
      30,
      1,
      [4],
      'Щётка для вычёсывания',
    ],
    [
      'JBL NovoBel',
      'JBL-001',
      'JBL',
      640,
      35,
      3,
      [5],
      'Корм для аквариумных рыб',
    ],
    [
      'JBL FilterStart',
      'JBL-002',
      'JBL',
      860,
      11,
      3,
      [5],
      'Средство запуска фильтра',
    ],
    [
      'JBL AquaBasis',
      'JBL-003',
      'JBL',
      1520,
      10,
      3,
      [5],
      'Грунт для аквариума',
    ],
    [
      'Beaphar Vitamin B',
      'BE-003',
      'Beaphar',
      1070,
      24,
      7,
      [6],
      'Витаминная добавка',
    ],
    [
      'Beaphar Dental Kit',
      'BE-004',
      'Beaphar',
      1390,
      15,
      7,
      [6],
      'Набор для ухода за зубами',
    ],
    [
      'Brit Care Dog',
      'BR-002',
      'Brit',
      2040,
      26,
      1,
      [1],
      'Гипоаллергенный корм',
    ],
    [
      'Миска Trixie',
      'TR-007',
      'Trixie',
      590,
      39,
      1,
      [3],
      'Металлическая миска',
    ],
    [
      'Flexi New Comfort',
      'FL-002',
      'Flexi',
      2690,
      12,
      1,
      [3],
      'Рулетка для прогулок',
    ],
    [
      'Purina Pro Plan',
      'PU-003',
      'Purina',
      2850,
      20,
      2,
      [1],
      'Премиальный корм для собак',
    ],
  ];

  for (const item of products) {
    push(
      'products',
      {
        name: item[0],
        article: item[1],
        brand: item[2],
        price: item[3],
        stock: item[4],
        supplierId: item[5],
        categoryIds: item[6],
        description: item[7],
      },
    );
  }


  // ==========================================================
  // ЖИВОТНЫЕ
  // ==========================================================

  const animals = [
    [
      'Барсик',
      'Кошка',
      'Британская короткошёрстная',
      5,
      'Самец',
      'Россия',
      35000,
      4,
      [7],
      'Спокойный британский котёнок',
    ],
    [
      'Луна',
      'Кошка',
      'Мейн-кун',
      6,
      'Самка',
      'Россия',
      48000,
      4,
      [7],
      'Активная и дружелюбная кошка',
    ],
    [
      'Рекс',
      'Собака',
      'Немецкая овчарка',
      8,
      'Самец',
      'Германия',
      70000,
      8,
      [8],
      'Умный и активный щенок',
    ],
    [
      'Белла',
      'Собака',
      'Лабрадор',
      7,
      'Самка',
      'Россия',
      65000,
      4,
      [8],
      'Дружелюбный щенок',
    ],
    [
      'Хома',
      'Хомяк',
      'Сирийский',
      3,
      'Самец',
      'Россия',
      2500,
      9,
      [9],
      'Молодой сирийский хомяк',
    ],
    [
      'Кеша',
      'Попугай',
      'Волнистый',
      5,
      'Самец',
      'Россия',
      4500,
      5,
      [10],
      'Активный волнистый попугай',
    ],
    [
      'Пушинка',
      'Кролик',
      'Карликовый',
      4,
      'Самка',
      'Россия',
      7000,
      9,
      [11],
      'Белый декоративный кролик',
    ],
    [
      'Тиша',
      'Морская свинка',
      'Американская',
      5,
      'Самец',
      'Россия',
      3500,
      9,
      [12],
      'Спокойная морская свинка',
    ],
    [
      'Мия',
      'Кошка',
      'Шотландская вислоухая',
      4,
      'Самка',
      'Россия',
      39000,
      4,
      [7],
      'Ласковая молодая кошка',
    ],
    [
      'Рио',
      'Попугай',
      'Корелла',
      9,
      'Самец',
      'Россия',
      12000,
      10,
      [10],
      'Ручной попугай корелла',
    ],
    [
      'Том',
      'Кошка',
      'Сибирская',
      8,
      'Самец',
      'Россия',
      32000,
      6,
      [7],
      'Спокойный сибирский кот',
    ],
    [
      'Джесси',
      'Собака',
      'Корги',
      6,
      'Самка',
      'Россия',
      85000,
      6,
      [8],
      'Активный щенок корги',
    ],
  ];

  for (const item of animals) {
    push(
      'animals',
      {
        name: item[0],
        species: item[1],
        breed: item[2],
        ageMonths: item[3],
        sex: item[4],
        country: item[5],
        price: item[6],
        supplierId: item[7],
        categoryIds: item[8],
        description: item[9],
      },
    );
  }


  // ==========================================================
  // ПОКУПАТЕЛИ
  // ==========================================================

  const customers = [
    [
      'Иван',
      'Петров',
      'ivan@example.ru',
      '+79990000001',
      'CARD-001',
      'Silver',
      120,
    ],
    [
      'Анна',
      'Смирнова',
      'anna@example.ru',
      '+79990000002',
      'CARD-002',
      'Gold',
      840,
    ],
    [
      'Максим',
      'Орлов',
      'max@example.ru',
      '+79990000003',
      'CARD-003',
      'Silver',
      90,
    ],
    [
      'Елена',
      'Кузнецова',
      'elena@example.ru',
      '+79990000004',
      'CARD-004',
      'Platinum',
      2400,
    ],
    [
      'Алексей',
      'Волков',
      'alex@example.ru',
      '+79990000005',
      'CARD-005',
      'Gold',
      730,
    ],
    [
      'Мария',
      'Морозова',
      'maria@example.ru',
      '+79990000006',
      'CARD-006',
      'Silver',
      210,
    ],
    [
      'Олег',
      'Соколов',
      'oleg@example.ru',
      '+79990000007',
      'CARD-007',
      'Gold',
      920,
    ],
    [
      'Дарья',
      'Лебедева',
      'daria@example.ru',
      '+79990000008',
      'CARD-008',
      'Platinum',
      3100,
    ],
    [
      'Роман',
      'Попов',
      'roman@example.ru',
      '+79990000009',
      'CARD-009',
      'Silver',
      160,
    ],
    [
      'Светлана',
      'Новикова',
      'sveta@example.ru',
      '+79990000010',
      'CARD-010',
      'Gold',
      660,
    ],
    [
      'Никита',
      'Фёдоров',
      'nikita@example.ru',
      '+79990000011',
      'CARD-011',
      'Silver',
      250,
    ],
    [
      'Ольга',
      'Васильева',
      'olga@example.ru',
      '+79990000012',
      'CARD-012',
      'Gold',
      1050,
    ],
  ];

  for (
    let i = 0;
    i < customers.length;
    i++
  ) {
    const item =
      customers[i];

    push(
      'customers',
      {
        firstName: item[0],
        lastName: item[1],
        email: item[2],
        phone: item[3],

        loyaltyCard: {
          number: item[4],
          level: item[5],
          points: item[6],

          issuedAt:
            new Date(
              Date.UTC(
                2026,
                0,
                10 + i,
              ),
            ).toISOString(),
        },
      },
    );
  }


  // ==========================================================
  // ПОЛЬЗОВАТЕЛИ И РОЛИ
  // ==========================================================

  push(
    'users',
    {
      username: 'admin',

      passwordHash:
        hash('admin123'),

      fullName:
        'Администратор',

      role: 'admin',
    },
  );

  push(
    'users',
    {
      username: 'manager',

      passwordHash:
        hash('manager123'),

      fullName:
        'Менеджер',

      role: 'manager',
    },
  );

  push(
    'users',
    {
      username: 'customer',

      passwordHash:
        hash('customer123'),

      fullName:
        'Покупатель',

      role: 'customer',
    },
  );
}


// ============================================================
// СВЯЗИ СУЩНОСТЕЙ
// ============================================================

function slimSupplier(id) {
  const supplier =
    db.suppliers.find(
      (item) =>
        item.id === id,
    );

  if (!supplier) {
    return null;
  }

  return {
    id: supplier.id,
    name: supplier.name,
  };
}

function slimCategories(
  categoryIds,
) {
  return categoryIds
    .map(
      (id) =>
        db.categories.find(
          (category) =>
            category.id === id,
        ),
    )
    .filter(Boolean)
    .map(
      (category) => ({
        id: category.id,
        name: category.name,
      }),
    );
}

function expandProduct(
  product,
) {
  return {
    id: product.id,

    name: product.name,
    article: product.article,
    brand: product.brand,

    price: product.price,
    stock: product.stock,

    supplier:
      slimSupplier(
        product.supplierId,
      ),

    categories:
      slimCategories(
        product.categoryIds,
      ),

    description:
      product.description,

    createdAt:
      product.createdAt,

    deletedAt:
      product.deletedAt,
  };
}

function expandAnimal(
  animal,
) {
  return {
    id: animal.id,

    name: animal.name,
    species: animal.species,
    breed: animal.breed,

    ageMonths:
      animal.ageMonths,

    sex: animal.sex,
    country: animal.country,

    price: animal.price,

    supplier:
      slimSupplier(
        animal.supplierId,
      ),

    categories:
      slimCategories(
        animal.categoryIds,
      ),

    description:
      animal.description,

    createdAt:
      animal.createdAt,

    deletedAt:
      animal.deletedAt,
  };
}

function expandSupplier(
  supplier,
) {
  return {
    ...supplier,

    allowedCategories:
      slimCategories(
        supplier.allowedCategoryIds,
      ),
  };
}

function expandUser(user) {
  return {
    id: user.id,
    username: user.username,
    fullName: user.fullName,
    role: user.role,
  };
}

const EXPANDERS = {
  products:
    expandProduct,

  animals:
    expandAnimal,

  categories:
    (item) => item,

  suppliers:
    expandSupplier,

  customers:
    (item) => item,
};

const COLLECTIONS =
  Object.keys(EXPANDERS);


// ============================================================
// ПОИСК
// ============================================================

function searchableText(
  collection,
  item,
) {
  switch (collection) {
    case 'products':
      return [
        item.name,
        item.article,
        item.brand,
      ].join(' ');

    case 'animals':
      return [
        item.name,
        item.species,
        item.breed,
        item.country,
      ].join(' ');

    case 'categories':
      return [
        item.name,
        item.kind,
        item.description,
      ].join(' ');

    case 'suppliers':
      return [
        item.name,
        item.country,
        item.email,
      ].join(' ');

    case 'customers':
      return [
        item.firstName,
        item.lastName,
        item.email,
        item.phone,
        item.loyaltyCard?.number,
      ].join(' ');

    default:
      return '';
  }
}


// ============================================================
// ФИЛЬТРАЦИЯ
// ============================================================

function applyFilters(
  collection,
  rows,
  query,
) {
  let result = rows;

  if (query.search) {
    const search =
      String(query.search)
        .trim()
        .toLowerCase();

    result =
      result.filter(
        (item) =>
          searchableText(
            collection,
            item,
          )
            .toLowerCase()
            .includes(search),
      );
  }

  if (
    collection ===
    'products'
  ) {
    if (query.categoryId) {
      result =
        result.filter(
          (item) =>
            item.categoryIds
              .includes(
                Number(
                  query.categoryId,
                ),
              ),
        );
    }

    if (query.supplierId) {
      result =
        result.filter(
          (item) =>
            item.supplierId ===
            Number(
              query.supplierId,
            ),
        );
    }

    if (query.priceFrom) {
      result =
        result.filter(
          (item) =>
            item.price >=
            Number(
              query.priceFrom,
            ),
        );
    }

    if (query.priceTo) {
      result =
        result.filter(
          (item) =>
            item.price <=
            Number(
              query.priceTo,
            ),
        );
    }
  }

  if (
    collection ===
    'animals'
  ) {
    if (query.species) {
      result =
        result.filter(
          (item) =>
            item.species ===
            query.species,
        );
    }

    if (query.sex) {
      result =
        result.filter(
          (item) =>
            item.sex ===
            query.sex,
        );
    }

    if (query.supplierId) {
      result =
        result.filter(
          (item) =>
            item.supplierId ===
            Number(
              query.supplierId,
            ),
        );
    }

    if (query.priceFrom) {
      result =
        result.filter(
          (item) =>
            item.price >=
            Number(
              query.priceFrom,
            ),
        );
    }

    if (query.priceTo) {
      result =
        result.filter(
          (item) =>
            item.price <=
            Number(
              query.priceTo,
            ),
        );
    }
  }

  if (
    collection ===
      'categories' &&
    query.kind
  ) {
    result =
      result.filter(
        (item) =>
          item.kind ===
          query.kind,
      );
  }

  if (
    collection ===
      'suppliers' &&
    query.country
  ) {
    result =
      result.filter(
        (item) =>
          item.country ===
          query.country,
      );
  }

  if (
    collection ===
      'customers' &&
    query.level
  ) {
    result =
      result.filter(
        (item) =>
          item.loyaltyCard
            ?.level ===
          query.level,
      );
  }

  return result;
}


// ============================================================
// СОРТИРОВКА
// ============================================================

function sortValue(
  collection,
  item,
  field,
) {
  if (
    collection ===
      'customers' &&
    field === 'points'
  ) {
    return item
      .loyaltyCard
      ?.points ?? 0;
  }

  return item[field];
}

function applySort(
  collection,
  rows,
  sort,
) {
  if (!sort) {
    return rows;
  }

  const parts =
    String(sort)
      .split(',');

  const field =
    parts[0];

  const direction =
    parts[1] === 'desc'
      ? -1
      : 1;

  return [...rows].sort(
    (a, b) => {
      const valueA =
        sortValue(
          collection,
          a,
          field,
        );

      const valueB =
        sortValue(
          collection,
          b,
          field,
        );

      if (
        valueA == null &&
        valueB == null
      ) {
        return 0;
      }

      if (valueA == null) {
        return 1;
      }

      if (valueB == null) {
        return -1;
      }

      if (
        typeof valueA ===
          'number' &&
        typeof valueB ===
          'number'
      ) {
        return (
          valueA - valueB
        ) * direction;
      }

      return String(valueA)
        .localeCompare(
          String(valueB),
          'ru',
        ) *
        direction;
    },
  );
}


// ============================================================
// ПАГИНАЦИЯ
// ============================================================

function paginate(
  rows,
  query,
) {
  const page =
    Math.max(
      1,
      Number(query.page) || 1,
    );

  const size =
    Math.min(
      100,
      Math.max(
        1,
        Number(query.size) ||
          10,
      ),
    );

  const total =
    rows.length;

  const totalPages =
    Math.max(
      1,
      Math.ceil(
        total / size,
      ),
    );

  return {
    items:
      rows.slice(
        (page - 1) * size,
        page * size,
      ),

    page,
    size,
    total,
    totalPages,
  };
}


// ============================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ВАЛИДАЦИИ
// ============================================================

function stringValue(value) {
  if (
    typeof value !==
    'string'
  ) {
    return '';
  }

  return value.trim();
}

function idList(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map(Number)
    .filter(
      Number.isInteger,
    );
}

function activeById(
  collection,
  id,
) {
  return db[collection]
    .find(
      (item) =>
        item.id ===
          Number(id) &&
        !item.deletedAt,
    );
}


// ============================================================
// ВАЛИДАЦИЯ СУЩНОСТЕЙ
// ============================================================

function validate(
  collection,
  body,
  id = null,
) {
  const errors = {};


  // ----------------------------------------------------------
  // PRODUCT
  // ----------------------------------------------------------

  if (
    collection ===
    'products'
  ) {
    const name =
      stringValue(
        body.name,
      );

    if (!name) {
      errors.name =
        'Укажите название';
    } else if (
      name.length > 100
    ) {
      errors.name =
        'Название не должно быть длиннее 100 символов';
    }

    const article =
      stringValue(
        body.article,
      );

    if (!article) {
      errors.article =
        'Укажите артикул';
    } else {
      const duplicate =
        db.products.find(
          (product) =>
            product.id !== id &&
            !product.deletedAt &&
            product.article
              .toLowerCase() ===
              article
                .toLowerCase(),
        );

      if (duplicate) {
        errors.article =
          'Товар с таким артикулом уже существует';
      }
    }

    if (
      !stringValue(
        body.brand,
      )
    ) {
      errors.brand =
        'Укажите бренд';
    }

    const price =
      Number(body.price);

    if (
      !Number.isFinite(price) ||
      price <= 0
    ) {
      errors.price =
        'Цена должна быть положительным числом';
    }

    const stock =
      Number(body.stock);

    if (
      !Number.isInteger(stock) ||
      stock < 0
    ) {
      errors.stock =
        'Остаток должен быть целым числом не меньше нуля';
    }

    const supplier =
      activeById(
        'suppliers',
        body.supplierId,
      );

    if (!supplier) {
      errors.supplierId =
        'Поставщик не найден';
    }

    const categoryIds =
      idList(
        body.categoryIds,
      );

    if (
      categoryIds.length === 0
    ) {
      errors.categoryIds =
        'Выберите хотя бы одну категорию';
    } else {
      const invalid =
        categoryIds.some(
          (categoryId) =>
            !activeById(
              'categories',
              categoryId,
            ),
        );

      if (invalid) {
        errors.categoryIds =
          'Одна из категорий не найдена';
      }

      const wrongKind =
        !invalid &&
        categoryIds.some(
          (categoryId) => {
            const category =
              activeById(
                'categories',
                categoryId,
              );

            return category &&
              ![
                'product',
                'both',
              ].includes(
                category.kind,
              );
          },
        );

      if (wrongKind) {
        errors.categoryIds =
          'Для товара выбрана категория животных';
      }

      if (
        !invalid &&
        !wrongKind &&
        supplier
      ) {
        const forbidden =
          categoryIds.some(
            (categoryId) =>
              !supplier
                .allowedCategoryIds
                .includes(
                  categoryId,
                ),
          );

        if (forbidden) {
          errors.categoryIds =
            'Поставщик не работает с одной из выбранных категорий';
        }
      }
    }
  }


  // ----------------------------------------------------------
  // ANIMAL
  // ----------------------------------------------------------

  if (
    collection ===
    'animals'
  ) {
    if (
      !stringValue(
        body.name,
      )
    ) {
      errors.name =
        'Укажите имя';
    }

    if (
      !stringValue(
        body.species,
      )
    ) {
      errors.species =
        'Укажите вид';
    }

    if (
      !stringValue(
        body.breed,
      )
    ) {
      errors.breed =
        'Укажите породу';
    }

    const age =
      Number(
        body.ageMonths,
      );

    if (
      !Number.isInteger(age) ||
      age < 1 ||
      age > 240
    ) {
      errors.ageMonths =
        'Возраст должен быть от 1 до 240 месяцев';
    }

    const sex =
      stringValue(
        body.sex,
      );

    if (
      ![
        'Самец',
        'Самка',
      ].includes(sex)
    ) {
      errors.sex =
        'Выберите пол';
    }

    if (
      !stringValue(
        body.country,
      )
    ) {
      errors.country =
        'Укажите страну';
    }

    const price =
      Number(
        body.price,
      );

    if (
      !Number.isFinite(price) ||
      price <= 0
    ) {
      errors.price =
        'Цена должна быть положительным числом';
    }

    const supplier =
      activeById(
        'suppliers',
        body.supplierId,
      );

    if (!supplier) {
      errors.supplierId =
        'Поставщик не найден';
    }

    const categoryIds =
      idList(
        body.categoryIds,
      );

    if (
      categoryIds.length === 0
    ) {
      errors.categoryIds =
        'Выберите хотя бы одну категорию';
    } else {
      const invalid =
        categoryIds.some(
          (categoryId) =>
            !activeById(
              'categories',
              categoryId,
            ),
        );

      if (invalid) {
        errors.categoryIds =
          'Одна из категорий не найдена';
      }

      const wrongKind =
        !invalid &&
        categoryIds.some(
          (categoryId) => {
            const category =
              activeById(
                'categories',
                categoryId,
              );

            return category &&
              ![
                'animal',
                'both',
              ].includes(
                category.kind,
              );
          },
        );

      if (wrongKind) {
        errors.categoryIds =
          'Для животного выбрана товарная категория';
      }

      if (
        !invalid &&
        !wrongKind &&
        supplier
      ) {
        const forbidden =
          categoryIds.some(
            (categoryId) =>
              !supplier
                .allowedCategoryIds
                .includes(
                  categoryId,
                ),
          );

        if (forbidden) {
          errors.categoryIds =
            'Поставщик не работает с одной из выбранных категорий';
        }
      }
    }
  }


  // ----------------------------------------------------------
  // CATEGORY
  // ----------------------------------------------------------

  if (
    collection ===
    'categories'
  ) {
    const name =
      stringValue(
        body.name,
      );

    if (!name) {
      errors.name =
        'Укажите название категории';
    }

    const duplicate =
      db.categories.find(
        (category) =>
          category.id !== id &&
          !category.deletedAt &&
          category.name
            .toLowerCase() ===
            name.toLowerCase(),
      );

    if (duplicate) {
      errors.name =
        'Такая категория уже существует';
    }

    const kind =
      stringValue(
        body.kind,
      );

    if (
      ![
        'product',
        'animal',
        'both',
      ].includes(kind)
    ) {
      errors.kind =
        'Выберите тип категории';
    }
  }


  // ----------------------------------------------------------
  // SUPPLIER
  // ----------------------------------------------------------

  if (
    collection ===
    'suppliers'
  ) {
    if (
      !stringValue(
        body.name,
      )
    ) {
      errors.name =
        'Укажите название поставщика';
    }

    if (
      !stringValue(
        body.country,
      )
    ) {
      errors.country =
        'Укажите страну';
    }

    const email =
      stringValue(
        body.email,
      );

    if (
      !/^[\w.+-]+@[\w-]+\.[\w.-]+$/
        .test(email)
    ) {
      errors.email =
        'Некорректный адрес почты';
    }

    const allowed =
      idList(
        body.allowedCategoryIds,
      );

    if (
      allowed.length === 0
    ) {
      errors.allowedCategoryIds =
        'Выберите хотя бы одну категорию';
    } else {
      const invalid =
        allowed.some(
          (categoryId) =>
            !activeById(
              'categories',
              categoryId,
            ),
        );

      if (invalid) {
        errors.allowedCategoryIds =
          'Одна из категорий не найдена';
      }
    }
  }


  // ----------------------------------------------------------
  // CUSTOMER
  // ----------------------------------------------------------

  if (
    collection ===
    'customers'
  ) {
    if (
      !stringValue(
        body.firstName,
      )
    ) {
      errors.firstName =
        'Укажите имя';
    }

    if (
      !stringValue(
        body.lastName,
      )
    ) {
      errors.lastName =
        'Укажите фамилию';
    }

    const email =
      stringValue(
        body.email,
      );

    if (
      !/^[\w.+-]+@[\w-]+\.[\w.-]+$/
        .test(email)
    ) {
      errors.email =
        'Некорректный адрес почты';
    } else {
      const duplicate =
        db.customers.find(
          (customer) =>
            customer.id !== id &&
            !customer.deletedAt &&
            customer.email
              .toLowerCase() ===
              email.toLowerCase(),
        );

      if (duplicate) {
        errors.email =
          'Покупатель с такой почтой уже зарегистрирован';
      }
    }

    const phone =
      stringValue(
        body.phone,
      );

    if (
      !/^\+?[0-9]{10,15}$/
        .test(phone)
    ) {
      errors.phone =
        'Некорректный телефон';
    }

    const card =
      body.loyaltyCard || {};

    if (
      !stringValue(
        card.number,
      )
    ) {
      errors.loyaltyCardNumber =
        'Укажите номер карты';
    }

    const level =
      stringValue(
        card.level,
      );

    if (
      ![
        'Silver',
        'Gold',
        'Platinum',
      ].includes(level)
    ) {
      errors.loyaltyCardLevel =
        'Выберите уровень карты';
    }

    const points =
      Number(
        card.points,
      );

    if (
      !Number.isInteger(points) ||
      points < 0
    ) {
      errors.loyaltyCardPoints =
        'Баллы должны быть целым числом не меньше нуля';
    }
  }

  return errors;
}


// ============================================================
// НОРМАЛИЗАЦИЯ
// ============================================================

function normalize(
  collection,
  body,
) {
  switch (collection) {
    case 'products':
      return {
        name:
          stringValue(
            body.name,
          ),

        article:
          stringValue(
            body.article,
          ),

        brand:
          stringValue(
            body.brand,
          ),

        price:
          Number(
            body.price,
          ),

        stock:
          Number(
            body.stock,
          ),

        supplierId:
          Number(
            body.supplierId,
          ),

        categoryIds:
          idList(
            body.categoryIds,
          ),

        description:
          stringValue(
            body.description,
          ),
      };


    case 'animals':
      return {
        name:
          stringValue(
            body.name,
          ),

        species:
          stringValue(
            body.species,
          ),

        breed:
          stringValue(
            body.breed,
          ),

        ageMonths:
          Number(
            body.ageMonths,
          ),

        sex:
          stringValue(
            body.sex,
          ),

        country:
          stringValue(
            body.country,
          ),

        price:
          Number(
            body.price,
          ),

        supplierId:
          Number(
            body.supplierId,
          ),

        categoryIds:
          idList(
            body.categoryIds,
          ),

        description:
          stringValue(
            body.description,
          ),
      };


    case 'categories':
      return {
        name:
          stringValue(
            body.name,
          ),

        kind:
          stringValue(
            body.kind,
          ),

        description:
          stringValue(
            body.description,
          ),
      };


    case 'suppliers':
      return {
        name:
          stringValue(
            body.name,
          ),

        country:
          stringValue(
            body.country,
          ),

        email:
          stringValue(
            body.email,
          ),

        allowedCategoryIds:
          idList(
            body.allowedCategoryIds,
          ),
      };


    case 'customers':
      return {
        firstName:
          stringValue(
            body.firstName,
          ),

        lastName:
          stringValue(
            body.lastName,
          ),

        email:
          stringValue(
            body.email,
          ),

        phone:
          stringValue(
            body.phone,
          ),

        loyaltyCard: {
          number:
            stringValue(
              body
                .loyaltyCard
                ?.number,
            ),

          level:
            stringValue(
              body
                .loyaltyCard
                ?.level,
            ),

          points:
            Number(
              body
                .loyaltyCard
                ?.points,
            ),

          issuedAt:
            body
              .loyaltyCard
              ?.issuedAt ??
            new Date()
              .toISOString(),
        },
      };

    default:
      return {
        ...body,
      };
  }
}


// ============================================================
// ПРОВЕРКА СВЯЗЕЙ ПРИ ФИЗИЧЕСКОМ УДАЛЕНИИ
// ============================================================

function references(
  collection,
  id,
) {
  if (
    collection ===
    'suppliers'
  ) {
    const productCount =
      db.products.filter(
        (product) =>
          product.supplierId ===
          id,
      ).length;

    const animalCount =
      db.animals.filter(
        (animal) =>
          animal.supplierId ===
          id,
      ).length;

    const total =
      productCount +
      animalCount;

    return {
      count: total,

      message:
        `Поставщик используется в связанных записях: ${total}`,
    };
  }

  if (
    collection ===
    'categories'
  ) {
    const productCount =
      db.products.filter(
        (product) =>
          product.categoryIds
            .includes(id),
      ).length;

    const animalCount =
      db.animals.filter(
        (animal) =>
          animal.categoryIds
            .includes(id),
      ).length;

    const supplierCount =
      db.suppliers.filter(
        (supplier) =>
          supplier
            .allowedCategoryIds
            .includes(id),
      ).length;

    const total =
      productCount +
      animalCount +
      supplierCount;

    return {
      count: total,

      message:
        `Категория используется в связанных записях: ${total}`,
    };
  }

  return {
    count: 0,
    message: '',
  };
}


// ============================================================
// CORS И HTTP
// ============================================================

function cors(response) {
  response.setHeader(
    'Access-Control-Allow-Origin',
    ORIGIN,
  );

  response.setHeader(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  );

  response.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization',
  );

  response.setHeader(
    'Access-Control-Max-Age',
    '86400',
  );

  response.setHeader(
    'Vary',
    'Origin',
  );
}

function send(
  response,
  status,
  payload,
) {
  cors(response);

  if (
    payload === undefined ||
    status === 204
  ) {
    response.writeHead(204);
    response.end();

    return;
  }

  const body =
    JSON.stringify(
      payload,
      null,
      2,
    );

  response.writeHead(
    status,
    {
      'Content-Type':
        'application/json; charset=utf-8',

      'Content-Length':
        Buffer.byteLength(
          body,
        ),
    },
  );

  response.end(body);
}

function fail(
  response,
  status,
  message,
) {
  send(
    response,
    status,
    {
      message,
    },
  );
}

async function readBody(
  request,
) {
  const chunks = [];

  for await (
    const chunk of request
  ) {
    chunks.push(chunk);
  }

  if (
    chunks.length === 0
  ) {
    return {};
  }

  try {
    return JSON.parse(
      Buffer
        .concat(chunks)
        .toString('utf8'),
    );
  } catch {
    return null;
  }
}


// ============================================================
// АВТОРИЗАЦИЯ
// ============================================================

function currentUser(
  request,
) {
  const header =
    request.headers[
      'authorization'
    ] || '';

  if (
    !header.startsWith(
      'Bearer ',
    )
  ) {
    return null;
  }

  const payload =
    verify(
      header.slice(7),
    );

  if (
    !payload ||
    payload.type !==
      'access'
  ) {
    return null;
  }

  return db.users.find(
    (user) =>
      user.id ===
        payload.sub &&
      !user.deletedAt,
  ) ?? null;
}

const ROLE_LEVEL = {
  customer: 1,
  manager: 2,
  admin: 3,
};

function requireRole(
  response,
  user,
  minimumRole,
) {
  if (!user) {
    fail(
      response,
      401,
      'Требуется аутентификация',
    );

    return false;
  }

  const currentLevel =
    ROLE_LEVEL[
      user.role
    ] || 0;

  const requiredLevel =
    ROLE_LEVEL[
      minimumRole
    ] || 999;

  if (
    currentLevel <
    requiredLevel
  ) {
    fail(
      response,
      403,
      'У вашей роли нет прав на выполнение этой операции',
    );

    return false;
  }

  return true;
}


// ============================================================
// ГЛАВНЫЙ ОБРАБОТЧИК API
// ============================================================

async function handle(
  request,
  response,
  url,
) {
  const query =
    Object.fromEntries(
      url.searchParams.entries(),
    );

  const path =
    url.pathname.replace(
      /\/+$/,
      '',
    ) || '/';

  const method =
    request.method
      .toUpperCase();

  const user =
    currentUser(request);


  // ==========================================================
  // ИСКУССТВЕННАЯ ОШИБКА
  // ==========================================================

  if (query.__fail) {
    return fail(
      response,
      Number(
        query.__fail,
      ),
      'Ошибка вызвана намеренно параметром __fail',
    );
  }


  // ==========================================================
  // HEALTH
  // ==========================================================

  if (
    path === '/api/__health' &&
    method === 'GET'
  ) {
    return send(
      response,
      200,
      {
        status: 'ok',

        time:
          new Date()
            .toISOString(),

        accessTokenTtl:
          ACCESS_TTL,
      },
    );
  }


  // ==========================================================
  // RESET
  // ==========================================================

  if (
    path === '/api/__reset' &&
    method === 'POST'
  ) {
    seed();

    return send(
      response,
      200,
      {
        message:
          'Данные восстановлены в исходное состояние',
      },
    );
  }


  // ==========================================================
  // РЕГИСТРАЦИЯ
  // ==========================================================

  if (
    path ===
      '/api/auth/register' &&
    method === 'POST'
  ) {
    const body =
      await readBody(
        request,
      );

    if (!body) {
      return fail(
        response,
        400,
        'Тело запроса не является корректным JSON',
      );
    }

    const username =
      stringValue(
        body.username,
      );

    const fullName =
      stringValue(
        body.fullName,
      );

    const password =
      String(
        body.password || '',
      );

    const errors = {};

    if (
      username.length < 3
    ) {
      errors.username =
        'Логин должен содержать минимум 3 символа';
    }

    if (
      username.length > 50
    ) {
      errors.username =
        'Логин не должен быть длиннее 50 символов';
    }

    if (!fullName) {
      errors.fullName =
        'Укажите имя пользователя';
    }

    if (
      fullName.length > 100
    ) {
      errors.fullName =
        'Имя не должно быть длиннее 100 символов';
    }

    if (
      password.length < 8
    ) {
      errors.password =
        'Пароль должен содержать минимум 8 символов';
    } else if (
      !/[0-9]/.test(
        password,
      )
    ) {
      errors.password =
        'Пароль должен содержать хотя бы одну цифру';
    } else if (
      !/[^A-Za-zА-Яа-яЁё0-9]/
        .test(
          password,
        )
    ) {
      errors.password =
        'Пароль должен содержать специальный символ';
    }

    const duplicate =
      db.users.find(
        (item) =>
          !item.deletedAt &&
          item.username
            .toLowerCase() ===
          username.toLowerCase(),
      );

    if (duplicate) {
      errors.username =
        'Такой логин уже занят';
    }

    if (
      Object.keys(errors)
        .length > 0
    ) {
      return send(
        response,
        422,
        {
          message:
            'Ошибка регистрации',

          errors,
        },
      );
    }

    const id = push(
      'users',
      {
        username,

        passwordHash:
          hash(password),

        fullName,

        // Самостоятельная регистрация
        // всегда создаёт покупателя.
        role: 'customer',
      },
    );

    const created =
      db.users.find(
        (item) =>
          item.id === id,
      );

    return send(
      response,
      201,
      expandUser(created),
    );
  }


  // ==========================================================
  // LOGIN
  // ==========================================================

  if (
    path ===
      '/api/auth/login' &&
    method === 'POST'
  ) {
    const body =
      await readBody(
        request,
      );

    if (!body) {
      return fail(
        response,
        400,
        'Тело запроса не является корректным JSON',
      );
    }

    const username =
      stringValue(
        body.username,
      );

    const password =
      String(
        body.password || '',
      );

    const found =
      db.users.find(
        (item) =>
          item.username ===
            username &&
          !item.deletedAt,
      );

    if (
      !found ||
      found.passwordHash !==
        hash(password)
    ) {
      return fail(
        response,
        401,
        'Неверный логин или пароль',
      );
    }

    const now =
      Math.floor(
        Date.now() / 1000,
      );

    const accessToken =
      sign({
        sub: found.id,
        role: found.role,
        type: 'access',

        exp:
          now +
          ACCESS_TTL,
      });

    const refreshToken =
      sign({
        sub: found.id,
        type: 'refresh',

        exp:
          now +
          REFRESH_TTL,
      });

    db.refreshTokens.add(
      refreshToken,
    );

    return send(
      response,
      200,
      {
        accessToken,
        refreshToken,

        expiresIn:
          ACCESS_TTL,

        user:
          expandUser(
            found,
          ),
      },
    );
  }


  // ==========================================================
  // REFRESH TOKEN
  // ==========================================================

  if (
    path ===
      '/api/auth/refresh' &&
    method === 'POST'
  ) {
    const body =
      await readBody(
        request,
      );

    const token =
      body?.refreshToken;

    const payload =
      verify(token);

    if (
      !payload ||
      payload.type !==
        'refresh' ||
      !db.refreshTokens.has(
        token,
      )
    ) {
      return fail(
        response,
        401,
        'Токен обновления недействителен или истёк',
      );
    }

    const found =
      db.users.find(
        (item) =>
          item.id ===
            payload.sub &&
          !item.deletedAt,
      );

    if (!found) {
      return fail(
        response,
        401,
        'Пользователь не найден',
      );
    }

    // Старый refresh-токен больше
    // использовать нельзя.
    db.refreshTokens.delete(
      token,
    );

    const now =
      Math.floor(
        Date.now() / 1000,
      );

    const accessToken =
      sign({
        sub: found.id,
        role: found.role,
        type: 'access',

        exp:
          now +
          ACCESS_TTL,
      });

    const refreshToken =
      sign({
        sub: found.id,
        type: 'refresh',

        exp:
          now +
          REFRESH_TTL,
      });

    db.refreshTokens.add(
      refreshToken,
    );

    return send(
      response,
      200,
      {
        accessToken,
        refreshToken,

        expiresIn:
          ACCESS_TTL,

        user:
          expandUser(
            found,
          ),
      },
    );
  }


  // ==========================================================
  // ТЕКУЩИЙ ПОЛЬЗОВАТЕЛЬ
  // ==========================================================

  if (
    path ===
      '/api/auth/me' &&
    method === 'GET'
  ) {
    if (!user) {
      return fail(
        response,
        401,
        'Требуется аутентификация',
      );
    }

    return send(
      response,
      200,
      expandUser(user),
    );
  }


  // ==========================================================
  // LOGOUT
  // ==========================================================

  if (
    path ===
      '/api/auth/logout' &&
    method === 'POST'
  ) {
    const body =
      await readBody(
        request,
      );

    if (
      body &&
      body.refreshToken
    ) {
      db.refreshTokens.delete(
        body.refreshToken,
      );
    }

    return send(
      response,
      204,
    );
  }


  // ==========================================================
  // ADMIN: СПИСОК ПОЛЬЗОВАТЕЛЕЙ
  // ==========================================================

  if (
    path ===
      '/api/admin/users' &&
    method === 'GET'
  ) {
    if (
      !requireRole(
        response,
        user,
        'admin',
      )
    ) {
      return;
    }

    return send(
      response,
      200,
      db.users
        .filter(
          (item) =>
            !item.deletedAt,
        )
        .map(expandUser),
    );
  }


  // ==========================================================
  // ADMIN: ИЗМЕНЕНИЕ РОЛИ
  // ==========================================================

  const roleMatch =
    path.match(
      /^\/api\/admin\/users\/(\d+)\/role$/,
    );

  if (
    roleMatch &&
    method === 'PUT'
  ) {
    if (
      !requireRole(
        response,
        user,
        'admin',
      )
    ) {
      return;
    }

    const id =
      Number(
        roleMatch[1],
      );

    if (
      user.id === id
    ) {
      return fail(
        response,
        409,
        'Нельзя изменить собственную роль',
      );
    }

    const target =
      db.users.find(
        (item) =>
          item.id === id &&
          !item.deletedAt,
      );

    if (!target) {
      return fail(
        response,
        404,
        'Пользователь не найден',
      );
    }

    const body =
      await readBody(
        request,
      );

    if (!body) {
      return fail(
        response,
        400,
        'Некорректное тело запроса',
      );
    }

    const role =
      stringValue(
        body.role,
      );

    if (
      ![
        'customer',
        'manager',
        'admin',
      ].includes(role)
    ) {
      return send(
        response,
        422,
        {
          message:
            'Ошибка валидации',

          errors: {
            role:
              'Неизвестная роль',
          },
        },
      );
    }

    target.role = role;

    return send(
      response,
      200,
      expandUser(target),
    );
  }


  // ==========================================================
  // ADMIN: СТАТИСТИКА
  // ==========================================================

  if (
    path ===
      '/api/admin/stats' &&
    method === 'GET'
  ) {
    if (
      !requireRole(
        response,
        user,
        'admin',
      )
    ) {
      return;
    }

    return send(
      response,
      200,
      {
        products:
          db.products
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        animals:
          db.animals
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        categories:
          db.categories
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        suppliers:
          db.suppliers
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        customers:
          db.customers
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        users:
          db.users
            .filter(
              (item) =>
                !item.deletedAt,
            ).length,

        deletedProducts:
          db.products
            .filter(
              (item) =>
                item.deletedAt,
            ).length,

        deletedAnimals:
          db.animals
            .filter(
              (item) =>
                item.deletedAt,
            ).length,
      },
    );
  }


  // ==========================================================
  // МНОЖЕСТВЕННОЕ ЛОГИЧЕСКОЕ УДАЛЕНИЕ
  // ==========================================================

  const bulk =
    path.match(
      /^\/api\/([a-z]+)\/bulk-delete$/,
    );

  if (
    bulk &&
    method === 'POST'
  ) {
    const collection =
      bulk[1];

    if (
      !COLLECTIONS.includes(
        collection,
      )
    ) {
      return fail(
        response,
        404,
        'Ресурс не найден',
      );
    }

    // Только менеджер или админ.
    if (
      !requireRole(
        response,
        user,
        'manager',
      )
    ) {
      return;
    }

    const body =
      await readBody(
        request,
      );

    const selected =
      Array.isArray(
        body?.ids,
      )
        ? body.ids
          .map(Number)
          .filter(
            Number.isInteger,
          )
        : [];

    if (
      selected.length === 0
    ) {
      return send(
        response,
        422,
        {
          message:
            'Ошибка валидации',

          errors: {
            ids:
              'Передайте непустой список идентификаторов',
          },
        },
      );
    }

    if (
      collection ===
        'categories' ||
      collection ===
        'suppliers'
    ) {
      for (
        const id of selected
      ) {
        const linked =
          references(
            collection,
            id,
          );

        if (
          linked.count > 0
        ) {
          return fail(
            response,
            409,
            linked.message,
          );
        }
      }
    }

    let deleted = 0;

    for (
      const item
      of db[collection]
    ) {
      if (
        selected.includes(
          item.id,
        ) &&
        !item.deletedAt
      ) {
        item.deletedAt =
          new Date()
            .toISOString();

        deleted++;
      }
    }

    return send(
      response,
      200,
      {
        deleted,
      },
    );
  }


  // ==========================================================
  // ОБЫЧНЫЙ CRUD
  // ==========================================================

  const match =
    path.match(
      /^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/,
    );

  if (match) {
    const collection =
      match[1];

    const id =
      match[2]
        ? Number(
          match[2],
        )
        : null;

    const action =
      match[3] || null;

    if (
      !COLLECTIONS.includes(
        collection,
      )
    ) {
      return fail(
        response,
        404,
        'Ресурс не найден',
      );
    }

    const expand =
      EXPANDERS[
        collection
      ];


    // --------------------------------------------------------
    // RESTORE
    // Только администратор.
    // --------------------------------------------------------

    if (
      action ===
        'restore' &&
      method === 'POST'
    ) {
      if (
        !requireRole(
          response,
          user,
          'admin',
        )
      ) {
        return;
      }

      const item =
        db[collection]
          .find(
            (row) =>
              row.id === id,
          );

      if (!item) {
        return fail(
          response,
          404,
          'Объект не найден',
        );
      }

      item.deletedAt =
        null;

      return send(
        response,
        200,
        expand(item),
      );
    }


    // --------------------------------------------------------
    // GET LIST
    // Каталог доступен всем авторизованным пользователям.
    // Покупатели доступны только manager/admin.
    // Удалённые записи доступны только manager/admin.
    // --------------------------------------------------------

    if (
      id === null &&
      method === 'GET'
    ) {
      const minimumReadRole =
        collection ===
          'customers'
          ? 'manager'
          : 'customer';

      if (
        !requireRole(
          response,
          user,
          minimumReadRole,
        )
      ) {
        return;
      }

      const canViewDeleted =
        user &&
        ROLE_LEVEL[user.role] >=
          ROLE_LEVEL.manager;

      let rows =
        db[collection];

      if (
        query.includeDeleted !==
          'true' ||
        !canViewDeleted
      ) {
        rows =
          rows.filter(
            (item) =>
              !item.deletedAt,
          );
      }

      rows =
        applyFilters(
          collection,
          rows,
          query,
        );

      rows =
        applySort(
          collection,
          rows,
          query.sort,
        );

      const page =
        paginate(
          rows,
          query,
        );

      return send(
        response,
        200,
        {
          ...page,

          items:
            page.items.map(
              expand,
            ),
        },
      );
    }


    // --------------------------------------------------------
    // GET ONE
    // Каталог доступен всем авторизованным пользователям.
    // Покупатели доступны только manager/admin.
    // Удалённые записи доступны только manager/admin.
    // --------------------------------------------------------

    if (
      id !== null &&
      method === 'GET'
    ) {
      const minimumReadRole =
        collection ===
          'customers'
          ? 'manager'
          : 'customer';

      if (
        !requireRole(
          response,
          user,
          minimumReadRole,
        )
      ) {
        return;
      }

      const canViewDeleted =
        user &&
        ROLE_LEVEL[user.role] >=
          ROLE_LEVEL.manager;

      const item =
        db[collection]
          .find(
            (row) =>
              row.id === id &&
              (
                (
                  query.includeDeleted ===
                    'true' &&
                  canViewDeleted
                ) ||
                !row.deletedAt
              ),
          );

      if (!item) {
        return fail(
          response,
          404,
          'Объект не найден',
        );
      }

      return send(
        response,
        200,
        expand(item),
      );
    }


    // --------------------------------------------------------
    // CREATE
    // Менеджер или администратор.
    // --------------------------------------------------------

    if (
      id === null &&
      method === 'POST'
    ) {
      if (
        !requireRole(
          response,
          user,
          'manager',
        )
      ) {
        return;
      }

      const body =
        await readBody(
          request,
        );

      if (!body) {
        return fail(
          response,
          400,
          'Тело запроса не является корректным JSON',
        );
      }

      const errors =
        validate(
          collection,
          body,
        );

      if (
        Object.keys(errors)
          .length > 0
      ) {
        return send(
          response,
          422,
          {
            message:
              'Ошибка валидации',

            errors,
          },
        );
      }

      const newId =
        push(
          collection,
          normalize(
            collection,
            body,
          ),
        );

      const item =
        db[collection]
          .find(
            (row) =>
              row.id ===
              newId,
          );

      return send(
        response,
        201,
        expand(item),
      );
    }


    // --------------------------------------------------------
    // UPDATE
    // Менеджер или администратор.
    // --------------------------------------------------------

    if (
      id !== null &&
      (
        method === 'PUT' ||
        method === 'PATCH'
      )
    ) {
      if (
        !requireRole(
          response,
          user,
          'manager',
        )
      ) {
        return;
      }

      const item =
        db[collection]
          .find(
            (row) =>
              row.id === id &&
              !row.deletedAt,
          );

      if (!item) {
        return fail(
          response,
          404,
          'Объект не найден',
        );
      }

      const body =
        await readBody(
          request,
        );

      if (!body) {
        return fail(
          response,
          400,
          'Тело запроса не является корректным JSON',
        );
      }

      const merged =
        method === 'PATCH'
          ? {
            ...item,
            ...body,

            ...(
              collection ===
                'customers' &&
              body.loyaltyCard
                ? {
                  loyaltyCard: {
                    ...item.loyaltyCard,
                    ...body.loyaltyCard,
                  },
                }
                : {}
            ),
          }
          : body;

      const errors =
        validate(
          collection,
          merged,
          id,
        );

      if (
        Object.keys(errors)
          .length > 0
      ) {
        return send(
          response,
          422,
          {
            message:
              'Ошибка валидации',

            errors,
          },
        );
      }

      Object.assign(
        item,
        normalize(
          collection,
          merged,
        ),
      );

      return send(
        response,
        200,
        expand(item),
      );
    }


    // --------------------------------------------------------
    // DELETE
    //
    // DELETE /resource/1
    // -> soft delete
    //
    // DELETE /resource/1?hard=true
    // -> hard delete
    // --------------------------------------------------------

    if (
      id !== null &&
      method === 'DELETE'
    ) {
      const hard =
        query.hard ===
        'true';

      // Soft delete:
      // manager или admin.
      //
      // Hard delete:
      // только admin.
      if (
        !requireRole(
          response,
          user,
          hard
            ? 'admin'
            : 'manager',
        )
      ) {
        return;
      }

      const index =
        db[collection]
          .findIndex(
            (item) =>
              item.id === id,
          );

      if (index === -1) {
        return fail(
          response,
          404,
          'Объект не найден',
        );
      }

      if (hard) {
        const linked =
          references(
            collection,
            id,
          );

        if (
          linked.count > 0
        ) {
          return fail(
            response,
            409,
            linked.message,
          );
        }

        db[collection]
          .splice(
            index,
            1,
          );
      } else {
        db[collection][index]
          .deletedAt =
          new Date()
            .toISOString();
      }

      return send(
        response,
        204,
      );
    }
  }


  // ==========================================================
  // 404
  // ==========================================================

  return fail(
    response,
    404,
    `Адрес ${method} ${path} не обслуживается`,
  );
}


// ============================================================
// ЗАПУСК СЕРВЕРА
// ============================================================

seed();

const server =
  http.createServer(
    async (
      request,
      response,
    ) => {
      const url =
        new URL(
          request.url,

          `http://${
            request.headers.host ||
            'localhost'
          }`,
        );


      // ------------------------------------------------------
      // CORS PREFLIGHT
      // ------------------------------------------------------

      if (
        request.method ===
        'OPTIONS'
      ) {
        cors(response);

        response.writeHead(
          204,
        );

        response.end();

        return;
      }


      // ------------------------------------------------------
      // ИСКУССТВЕННАЯ ЗАДЕРЖКА
      // ------------------------------------------------------

      const delay =
        Number(
          url.searchParams.get(
            '__delay',
          ) || 0,
        );

      if (delay > 0) {
        await new Promise(
          (resolve) =>
            setTimeout(
              resolve,
              Math.min(
                delay,
                10000,
              ),
            ),
        );
      }


      // ------------------------------------------------------
      // ЛОГИРОВАНИЕ
      // ------------------------------------------------------

      const started =
        Date.now();

      try {
        await handle(
          request,
          response,
          url,
        );
      } catch (error) {
        console.error(
          error,
        );

        if (
          !response.headersSent
        ) {
          fail(
            response,
            500,
            `Внутренняя ошибка сервера: ${
              error.message
            }`,
          );
        }
      }

      console.log(
        `${request.method.padEnd(6)} ` +
        `${url.pathname}${url.search} ` +
        `-> ${response.statusCode} ` +
        `${Date.now() - started} ms`,
      );
    },
  );

server.listen(
  PORT,
  () => {
    console.log('');
    console.log(
      '============================================',
    );

    console.log(
      '  Учебное REST API «Зоомагазин»',
    );

    console.log(
      '============================================',
    );

    console.log('');

    console.log(
      `API: http://localhost:${PORT}/api`,
    );

    console.log(
      `CORS origin: ${ORIGIN}`,
    );

    console.log(
      `Access token TTL: ${ACCESS_TTL} сек.`,
    );

    console.log('');

    console.log(
      'Тестовые пользователи:',
    );

    console.log(
      'customer / customer123',
    );

    console.log(
      'manager  / manager123',
    );

    console.log(
      'admin    / admin123',
    );

    console.log('');

    console.log(
      'Дополнительные возможности:',
    );

    console.log(
      'GET  /api/__health',
    );

    console.log(
      'POST /api/__reset',
    );

    console.log(
      '?__delay=1500',
    );

    console.log(
      '?__fail=500',
    );

    console.log('');

    console.log(
      'Для проверки refresh:',
    );

    console.log(
      'node mock-server.js --port 8080 ' +
      '--origin http://localhost:5555 --ttl 60',
    );

    console.log('');
  },
);
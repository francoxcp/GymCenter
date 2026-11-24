# Comida por porciones de intercambio — diseño

Fecha: 2026-11-24 · Estado: aprobado por el dueño ("Está bien así, hazlo")

## Intención
Que el plan de Comida sea más preciso y variado, al estilo de un plan de
nutricionista (sistema de intercambios), sin que el socio tenga que entender
porciones: elige un plato ya armado y las cantidades salen exactas para él.

## Enfoques
| Enfoque | Trade-off | Decisión |
|---|---|---|
| A. Listas por grupo (elige 1 harina, 1 proteína…) | Máxima libertad; el socio arma cada comida | Descartado |
| **B. Combinaciones listas calculadas con porciones** | El socio solo elige un plato; cada plato respeta sus porciones | **Elegido** |

## Cálculo
1. Calorías, proteína y grasa del día: igual que hoy (`computeTargets`).
2. Porciones del día (valores de intercambio estándar):
   harina 15 g CHO · 3 g P · 1 g G · 80 kcal; proteína baja en grasa 7 g P ·
   3 g G · 55 kcal; grasa 5 g G · 45 kcal; fruta 15 g CHO · 60 kcal;
   vegetal 5 g CHO · 2 g P · 25 kcal.
   - Vegetales 2 (subir masa 3), frutas 2.
   - Proteínas = (proteína objetivo − 3·harinas − 2·vegetales) / 7.
   - Harinas = calorías restantes / 80 tras proteínas, grasas, frutas y vegetales.
   - Grasas = (grasa objetivo − harinas − 3·proteínas) / 5, mínimo 2.
   - Redondeo a medias porciones; mínimos de seguridad (harinas ≥ 3, proteínas ≥ 6).
3. Reparto por comida, patrón del plan de referencia:
   desayuno harina + proteína + grasa (+ fruta si no hay merienda AM);
   merienda AM fruta; almuerzo y cena harinas + proteína + vegetal + grasa;
   merienda PM harina + proteína + fruta. Con 3 comidas, lo de las meriendas
   se reparte en las principales.

## Platos
- Cada plato es una plantilla de componentes (alimento + grupo + parte del
  grupo que cubre). La cantidad de cada alimento = porciones del grupo en esa
  comida × parte × gramos por porción del alimento, en medidas caseras.
- Si la comida pide un grupo que el plato no trae: grasa → "aceite para
  cocinar"; vegetal → "ensalada verde o vegetales al vapor"; fruta → "1 fruta".
- 10–12 platos por comida principal, ~8 meriendas, ~6 frutas. Comida tica,
  nombres genéricos sin marcas. Proteína pesada ya cocinada.
- Calorías y proteína mostradas = las reales de los alimentos en esas cantidades.

## Pantalla
- Bajo los chips: "2 harinas · 5 proteínas · ½ vegetal · 2 grasas".
- Consejos fijos: 2 L de agua, caminar 10–15 min después de comer, pesar la
  proteína cocida, plancha/horno/freidora de aire, la fruta de la tarde como
  pre-entreno.

## No-objetivos
Variar porciones por día de pierna/tren superior; suplementos; editar
platos desde la app; listas por grupo (enfoque A).

## Se conserva
Cuestionario, exclusiones, menores de 18, elección del día, aviso de guía
orientativa.

# Problems with the question
# 1. Ambiguity in whether only sales tax is rounded or sales tax and import duty.  Ambiguity remains on whether the
# rounding applies to round(sales tax + import tax) * cost), or round(sales_tax * cost) + round(import_tax * cost)
# which will have different results depending on cost and rates.
# Inspecting the expected output, it would seem that the round applies after sales tax and import tax have been summed.

# 2. Ambiguity in parsing the input "1 box of imported chocolates" and the expected output "1 imported box of chocolates",
# as an imported box is semantically different than a "box of imported..." and quite possibly also two different things.

# Constants, since this is only demo code.

NON_TAX_ITEMS = ['book', 'chocolate bar', 'box of chocolates', 'packet of headache pills']
SALES_TAX_RATE = 0.10
IMPORT_TAX_RATE =0.05   # The import duty

# Assertion helper.
def assert(error_text, &block)
  raise Exception.new(error_text) unless yield block
end

# String extensions to validate integers and reals.
class String
  def is_integer?
    !!(self =~ /^[-+]?[0-9]+$/)
  end

  def is_real?
    !!(self =~ /^-*[0-9,\.]+$/)
  end
end

# Contains a basket item, which consists of the quantity, item, and cost of item.
class BasketItem
  # Accessors for summing function of the basket itself.
  attr_accessor :sales_tax
  attr_accessor :cost_with_tax

  def initialize(item_name, cost, qty = 1, is_imported = false)
    assert("Item name must be supplied") {!item_name.empty?}
    assert("Cost cannot be <= 0") {cost > 0}
    assert("Quantity cannot be < 1") {qty >= 1}

    @item_name = item_name
    @cost = cost
    @quantity = qty
    @is_imported = is_imported

    calculate_taxes
  end

  # Format the item into a string, returning "[imported] item-name: cost-with-tax"
  def format
    output = [@quantity.to_s]
    # imported always comes first in the reconstituted item name.
    # For example, receipt 3's input is: 1 box of imported chocolates at 11.25
    # and the output should be: 1 imported box of chocolates: 11.85
    output << 'imported' if @is_imported
    output << (@item_name + ':')
    output << sprintf('%.2f', @cost_with_tax)
    output = output.join(' ')
  end

  private

  def calculate_taxes
    @import_tax = 0.0
    @sales_tax = 0.0
    tax_rate = 0

    if @is_imported
      # no rounding on import tax according to the spec:
      # The rounding rules for sales tax are...
      tax_rate = IMPORT_TAX_RATE
    end

    if !NON_TAX_ITEMS.include?(@item_name)
      # According to the spec, sales tax is rounded:
      # rounded up to the nearest 0.05) amount of sales tax.
      # This is a bit ambiguous - is the tax itself rounded, or the cost + tax rounded?
      # We assume the above means tat the tax itself is rounded, then added to the cost.
      tax_rate += SALES_TAX_RATE
    end

    # round cost * taxes up to nearest .05
    @sales_tax = (@cost * tax_rate * 20).ceil / 20.0
    @cost_with_tax = (@cost + @sales_tax).round(2)
  end
end

# A shopping basket, containing basket items.
class ShoppingBasket
  def initialize
    @basket = []
  end

  # Simply add an item to our basket.
  def add_item(item_name, cost, qty = 1, is_imported = false)
    basket_item = BasketItem.new(item_name, cost, qty, is_imported)
    @basket << basket_item
  end

  def generate_receipt
    total_sales_tax = 0
    total = 0

    @basket.each do |item|
      puts(item.format)
      total_sales_tax += item.sales_tax
      total += item.cost_with_tax
    end

    puts("Sales Taxes: " + sprintf('%.2f', total_sales_tax))
    puts("Total: " + sprintf('%.2f', total))
  end
end

# Given an item description in the form [qty] [item name] at [cost],
# returns a struct consisting of the item name, cost, and quantity, and whether it's imported or not.
# This is not part of the basket -- the parser is an autonomous function.
def parse(item_descr)
  item = OpenStruct.new
  pieces = item_descr.split(' ')

  # where "n" is the length of the array "pieces":
  # we expect pieces[0] to be a non-zero integer
  # we expect pieces[n-2] to be the text "at"
  # we expect pieces[n-1] to be the cost (a parseable real)
  # everything between [1..n-3] is the item name, at least one value must exist

  n = pieces.count
  assert('Expected item in the form [qty] [item name] at [cost]') {n >= 4}
  assert('Expected item in the form [qty] [item name] at [cost] -- missing "at"') {pieces[n-2] == 'at'}
  qty = pieces[0]
  cost = pieces[n-1]

  # check for the text "imported" and set the imported flag to true if so, and
  # remove the "imported" from the item name.
  # Check for the text "imported" occurring anywhere in the description, accounting for casing.
  imported_idx = (pieces.map {|p| p.downcase}).index('imported')
  # Set the imported flag.
  item.is_imported = imported_idx.nil? ? false : true
  # Reconstitute the item name, without the text "imported" if it occurs.
  item.is_imported ? item.item_name = (pieces[1..imported_idx-1] << pieces[imported_idx+1..n-3]).join(' ') : item.item_name = pieces[1..n-3].join(' ')

  assert('Quantity is not an integer') {qty.is_integer?}
  item.iqty = qty.to_i
  assert('Quantity must be greater than 0') {item.iqty > 0}
  assert('Cost is not a number') {cost.is_real?}
  item.fcost = cost.to_f
  assert('Cost must be greater than 0') {item.fcost > 0}

  return item
end

def generate_receipt(header, items)
  puts header
  basket = ShoppingBasket.new

  items.each do |item|
      parsed_item = parse(item)
      basket.add_item(parsed_item.item_name, parsed_item.fcost, parsed_item.iqty, parsed_item.is_imported)
  end

  basket.generate_receipt
end

input1 = ['1 book at 12.49', '1 music CD at 14.99', '1 chocolate bar at 0.85']
input2 = ['1 imported box of chocolates at 10.00', '1 imported bottle of perfume at 47.50']
input3 = ['1 imported bottle of perfume at 27.99', '1 bottle of perfume at 18.99', '1 packet of headache pills at 9.75', '1 box of imported chocolates at 11.25']

generate_receipt("Ouptut 1:", input1)
puts

generate_receipt("Ouptut 2:", input2)
puts

generate_receipt("Ouptut 3:", input3)



require 'rails_helper'

RSpec.shared_examples 'Geocodeable' do
  let(:model) { described_class }

  let(:address_attr) { model.geocodeable_address_attr }
  let(:attr_mappings) { model.geocodeable_attr_mappings }

  geocoded_attrs = [
    :latitude, :longitude,
    :address,
    :city,
    :state, :state_code,
    :postal_code,
    :country, :country_code
  ]

  def address(obj, attr = address_attr)
    obj.send(attr)
  end

  def set_address(obj, new_address, attr = address_attr)
    obj.send("#{attr}=", new_address)
  end

  def get_val(obj, attr)
    obj.send(attr)
  end

  describe 'geocoding' do
    let!(:obj) { create(described_class.to_s.underscore.to_sym) }
    let!(:original_address) { address(obj) }

    before do
      Geocoder::Lookup::Test.set_default_stub(
        [
          {
            'latitude' => 42.42,
            'longitude' => -42.42,
            'address' => '576 Natoma St, San Francisco, CA 94103, USA',
            'city' => 'San Francisco',
            'state' => 'California',
            'state_code' => 'CA',
            'postal_code' => '94103',
            'country' => 'United States',
            'country_code' => 'US'
          }
        ]
      )
    end

    after { Geocoder::Lookup::Test.reset }

    context 'when address changes' do
      geocoded_attrs.each do |attr|
        it "updates #{attr}" do
          mapped_attr = attr_mappings[attr]

          expect do
            set_address(obj, 'NEW ADDRESS')
            obj.save
          end.to change { get_val(obj.reload, mapped_attr) }
        end
      end
    end

    context "when address doesn't change" do
      it "doesn't geocode" do
        expect(obj).to_not receive(:geocode)
        obj.save
      end
    end
  end
end

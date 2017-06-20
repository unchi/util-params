module Util
  module Params

    # コンストラクタ
    def initialize
      super
      # エラーフラグ
      @is_error = false
      # エラーリスト
      @errors = []
    end

    module Type
      INTEGER = :integer
      STRING  = :string
      FLOAT   = :float
      FILE    = :file
      BOOLEAN = :boolean
      OBJECT  = :object
      ARRAY   = :array
    end

    def get_params options
      options = options.deep_symbolize_keys

      key = options[:key]
      val = _load_val params.permit!.to_h, key, options[:default], options[:require]

      return nil if val.nil?

      _validate key, options[:type], val, options
    end

    def get_int_params key, options={}
      get_params options.merge(key: key, type: Type::INTEGER)
    end

    def get_str_params key, options={}
      get_params options.merge(key: key, type: Type::STRING)
    end

    def get_float_params key, options={}
      get_params options.merge(key: key, type: Type::FLOAT)
    end

    def get_file_params key, options={}
      get_params options.merge(key: key, type: Type::FILE)
    end

    def get_bool_params key, options={}
      get_params options.merge(key: key, type: Type::BOOLEAN)
    end

    def get_array_params key, options={}
      get_params options.merge(key: key, type: Type::ARRAY)
    end

    def get_object_params key, options={}
      get_params options.merge(key: key, type: Type::OBJECT)
    end


    # エラーがあるか
    def has_params_error?
      @is_error
    end
    # エラーメッセージ入りスト
    def get_params_error
      @errors.join ', '
    end
  
  protected

    def _load_val vals, key, default, is_require

      unless vals.try(:has_key?, key)
        _push_error "#{key.to_s} == nil" if is_require
        return default
      end

      vals[key]
    end

    def _validate key_label, type, val, options
      options ||= {}

      case type
      when Type::INTEGER
        _validate_int key_label, val, options[:min], options[:max], options[:enum]
      when Type::STRING
        _validate_str key_label, val, options[:min], options[:max], options[:enum], options[:reg]
      when Type::FLOAT
        _validate_float key_label, val, options[:min], options[:max]
      when Type::BOOLEAN
        _validate_bool key_label, val
      when Type::FILE
        _validate_file key_label, val
      when Type::OBJECT
        _validate_object key_label, val, options[:elements]
      when Type::ARRAY
        vals = _validate_array key_label, val, options[:min], options[:max]
        return nil if vals.nil?
        elem_options = options[:element] || {}
        elem_type = elem_options[:type] || Type::STRING

        vals.map.with_index do |_, i|
          elem_val = vals[i]
          _validate "#{key_label}[#{i}]", elem_type, elem_val, elem_options
        end
      else
        # do nothing
      end

    end

    def _validate_int key, val, min, max, enum
      return nil if val.blank?

      if /[^\d]/ =~ val.to_s
        _push_error "#{key.to_s} type [#{val.to_s}] != integer"
      end

      v = val.to_i

      if enum
        for e in enum
          return v if e === v
        end
        _push_error "#{key.to_s} == unknown val [#{v.to_s}]"
      end

      if min && (v < min)
        _push_error "#{key.to_s} val [#{v.to_s}] < #{min.to_s}"
      end

      if max && (v > max)
        _push_error "#{key.to_s} val [#{v.to_s}] > #{max.to_s}"
      end

      v
    end

    def _validate_str key, val, min, max, enum, reg
      return nil if val.nil?

      v = val.to_s

      if enum
        enum.each do |e|
          return v if e === v
        end
        _push_error "#{key.to_s} == unknown val [#{v.to_s}]"
      end

      if min && (v.length < min)
        _push_error "#{key.to_s}.length < #{min.to_s} ('#{v.to_s}')"
      end

      if max && (v.length > max)
        _push_error "#{key.to_s}.length > #{max.to_s} ('#{v.to_s}')"
      end

      if reg && !(/#{reg}/ =~ val)
        _push_error "#{key.to_s} unmatch /#{reg.to_s}/ =~ [#{v.to_s}]"
      end

      v
    end

    def _validate_float key, val, min, max
      return nil if val.blank?

      if /[^\d.]/ =~ val.to_s
        _push_error "#{key.to_s} type [#{val.to_s}] != float"
      end

      v = val.to_f

      if min && (v < min)
        _push_error "#{key.to_s} val [#{v.to_s}] < #{min.to_s}"
      end

      if max && (v > max)
        _push_error "#{key.to_s} val [#{v.to_s}] > #{max.to_s}"
      end

      v     
    end

    def _validate_bool key, val
      return false if val.kind_of? FalseClass
      return true if val.kind_of? TrueClass
      return nil if val.blank?
      return false if val == 'false'
      return true if val == 'true'
      return false if val == '0'
      true
    end

    def _validate_file key, val
      return nil if val.nil?

      if val.size.blank?
        _push_error "#{key.to_s} == nil"
        return nil
      end

      return nil if val.nil?
      return nil if val.size.blank?

      val
    end

    def _validate_array key, val, min, max
      return nil if val.nil?

      unless val.kind_of? Array
        _push_error "#{key.to_s}.type != Array"
        return nil
      end

      v = val

      if min && (v.length < min)
        _push_error "#{key.to_s} val [#{v.to_s}.length] < #{min.to_s}"
      end

      if max && (v.length > max)
        _push_error "#{key.to_s} val [#{v.to_s}.length] > #{max.to_s}"
      end

      v
    end

    def _validate_object key, val, elements
      return nil if val.nil?

      unless val.kind_of? Hash
        _push_error "#{key.to_s}.type != Hash"
        return nil
      end

      r = {}

      if elements.nil?
        return val.to_h
      end

      elements.map do |options|
        options ||= {}
        elem_key = options[:key]
        elem_type = options[:type]
        elem_default = options[:default]
        elem_require = options[:require]
        elem_val = _load_val val, elem_key, elem_default, elem_require

        r[elem_key] = _validate("#{key}[#{elem_key}]", elem_type, elem_val, options)
      end
      r
    end

    # エラー追加
    def _push_error message
      @is_error |= true
      @errors.push message
    end
  
  end

end

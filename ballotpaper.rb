class BallotPaper
  def initialize(elec, booth_id, batch, paper, prefs, tickets)
    @elec = elec
    @booth_id = booth_id.to_i
    @batch = batch.to_i
    @paper = paper.to_i
    @btl = fix_pref(prefs[tickets..-1])
    @atl = fix_pref(prefs[0..(tickets - 1)])
    @btl_formal = check_btl_formal
    @atl_formal = check_atl_formal
    @cur_candidate = nil
    @is_exhaust = false
    @value = 1.0
    @round_last_updated = 1
  end

  attr_reader :btl_formal, :paper, :batch, :atl_formal, :atl
  attr_accessor :cur_candidate, :is_exhaust, :value, :btl, :round_last_updated

  def fix_pref(pref)
    result = []
    if pref.nil?
      nil
    else
      pref.each do |b|
        result << if b.nil? || b.empty?
                    nil
                  elsif ['*', '/'].include?(b)
                    1
                  else
                    b.to_i
                  end
      end
      result
    end
  end

  def check_btl_formal
    if btl.nil?
      false
    elsif btl.count(1) == 1 && btl.count(2) == 1 && btl.count(3) == 1 && btl.count(4) == 1 && btl.count(5) == 1 && btl.count(6) == 1
      true
    else
      false
    end
  end

  def check_atl_formal
    if btl_formal
      false
    else
      atl.count(1) == 1
    end
  end
end

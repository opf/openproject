require 'rexml/document'
require 'rexml/element'
require 'rexml/xpath'

require 'openid/yadis/xri'

module OpenID
  module Yadis

    XRD_NS_2_0 = 'xri://$xrd*($v*2.0)'
    XRDS_NS = 'xri://$xrds'

    XRDS_NAMESPACES = {
      'xrds' => XRDS_NS,
      'xrd' => XRD_NS_2_0,
    }

    class XRDSError < StandardError; end

    # Raised when there's an assertion in the XRDS that it does not
    # have the authority to make.
    class XRDSFraud < XRDSError
    end

    def Yadis::get_canonical_id(iname, xrd_tree)
      # Return the CanonicalID from this XRDS document.
      #
      # @param iname: the XRI being resolved.
      # @type iname: unicode
      #
      # @param xrd_tree: The XRDS output from the resolver.
      #
      # @returns: The XRI CanonicalID or None.
      # @returntype: unicode or None

      xrd_list = []
      REXML::XPath::match(xrd_tree.root, '/xrds:XRDS/xrd:XRD', XRDS_NAMESPACES).each { |el|
        xrd_list << el
      }

      xrd_list.reverse!

      cid_elements = []

      if !xrd_list.empty?
        xrd_list[0].elements.each { |e|
          if !e.respond_to?('name')
            next
          end
          if e.name == 'CanonicalID'
            cid_elements << e
          end
        }
      end

      cid_element = cid_elements[0]

      if !cid_element
        return nil
      end

      canonicalID = XRI.make_xri(cid_element.text)

      childID = canonicalID.downcase

      xrd_list[1..-1].each { |xrd|
        parent_sought = childID[0...childID.rindex('!')]

        parent = XRI.make_xri(xrd.elements["CanonicalID"].text)

        if parent_sought != parent.downcase
          raise XRDSFraud.new(sprintf("%s can not come from %s", parent_sought,
                                      parent))
        end

        childID = parent_sought
      }

      root = XRI.root_authority(iname)
      if not XRI.provider_is_authoritative(root, childID)
        raise XRDSFraud.new(sprintf("%s can not come from root %s", childID, root))
      end

      return canonicalID
    end

    class XRDSError < StandardError
    end

    def Yadis::parseXRDS(text)
      if text.nil?
        raise XRDSError.new("Not an XRDS document.")
      end

      begin
        d = REXML::Document.new(text)
      rescue RuntimeError => why
        raise XRDSError.new("Not an XRDS document. Failed to parse XML.")
      end

      if is_xrds?(d)
        return d
      else
        raise XRDSError.new("Not an XRDS document.")
      end
    end

    def Yadis::is_xrds?(xrds_tree)
      xrds_root = xrds_tree.root
      return (!xrds_root.nil? and
        xrds_root.name == 'XRDS' and
        xrds_root.namespace == XRDS_NS)
    end

    def Yadis::get_yadis_xrd(xrds_tree)
      REXML::XPath.each(xrds_tree.root,
                        '/xrds:XRDS/xrd:XRD[last()]',
                        XRDS_NAMESPACES) { |el|
        return el
      }
      raise XRDSError.new("No XRD element found.")
    end

    # aka iterServices in Python
    def Yadis::each_service(xrds_tree, &block)
      xrd = get_yadis_xrd(xrds_tree)
      xrd.each_element('Service', &block)
    end

    def Yadis::services(xrds_tree)
      s = []
      each_service(xrds_tree) { |service|
        s << service
      }
      return s
    end

    def Yadis::expand_service(service_element)
      es = service_element.elements
      uris = es.each('URI') { |u| }
      uris = prio_sort(uris)
      types = es.each('Type/text()')
      # REXML::Text objects are not strings.
      types = types.collect { |t| t.to_s }
      uris.collect { |uri| [types, uri.text, service_element] }
    end

    # Sort a list of elements that have priority attributes.
    def Yadis::prio_sort(elements)
      elements.sort { |a,b|
        a.attribute('priority').to_s.to_i <=> b.attribute('priority').to_s.to_i
      }
    end
  end
end


    class VerbNoun {
        [string]$Verb
        [string]$Noun
        #[string]$Prefix
        hidden $Parent

        [void] AddPrefix () {
            $getter = {
                return $this.Parent.Prefix
                }

            $setter = {
                param($string)
                $this.Parent.Prefix = $string
                }

            $splat = @{
                Name = 'Prefix'
                MemberType = 'ScriptProperty'
                Value = $getter
                SecondValue = $setter
                }

            Add-Member -InputObject $this @splat
            }

        [string]PSName() {
            filter Capitalize {
                [Regex]::Replace($_, '^\w', { param($letter) $letter.Value.ToUpper() })
                }
            $tmpVerb = $this.Verb | Capitalize
            $tmpNoun = $this.Noun | Capitalize
            return ('{0}-{2}{1}' -f $tmpVerb, $tmpNoun, $this.Parent.Prefix)
            }

        VerbNoun (
            [string]$newVerb,
            [string]$newNoun,
            $Parent
            )
            {
                $this.Verb = $newVerb
                $this.Noun = $newNoun
                $this.Parent = $Parent
                $this.AddPrefix()
                }

        VerbNoun (
            $Parent
            )
            {
                $this.Parent = $Parent
                $this.AddPrefix()
                }

        [string] ToString () {
            return $this.PSName()
            }

        }


    class ApiObject {
        [string]$name
        [VerbNoun]$PSName
        [string]$Prefix
    
        ApiObject() {
            $this.PSName = [VerbNoun]::New($this)
            }
        }

    $b = [ApiObject]::new()
    $b.PSName.Verb = 'get'
    $b.PSName.Noun = 'rekt'

    $b.Prefix = 'PS'
    'Function name: {0}; Prefix: {1}; PSName.Prefix: {2}' -f $b.PSName, $b.Prefix, $b.PSName.Prefix

    $b.PSName.Prefix = 'Test'
    'Function name: {0}; Prefix: {1}; PSName.Prefix: {2}' -f $b.PSName, $b.Prefix, $b.PSName.Prefix
